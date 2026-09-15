package com.woxsen.greenmobility.dao;

import com.woxsen.greenmobility.model.Booking;
import com.woxsen.greenmobility.util.DBUtil;
import com.woxsen.greenmobility.util.RideTimingUtil;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

public class BookingDAO {

    /** Total green trips booked across all students, shown on the login page. */
    public int getCampusTotalTrips() throws SQLException {
        String sql = "SELECT COUNT(*) FROM bookings";
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            return rs.next() ? rs.getInt(1) : 0;
        }
    }

    /**
     * The most recently completed ride this student hasn't left feedback on
     * yet — what drives the auto-prompt shown right after a ride finishes,
     * as opposed to history.jsp's "Rate this ride" button which the student
     * has to notice and click themselves. A LEFT JOIN (rather than the
     * NOT IN subquery findLegitimateCompletedBookings uses) since this only
     * ever needs the single newest match.
     */
    public Booking findMostRecentUnrated(int studentId) throws SQLException {
        String sql = "SELECT b.*, s.vehicle_type, s.route, s.slot_time " +
                     "FROM bookings b " +
                     "JOIN vehicle_slots s ON b.slot_id = s.slot_id " +
                     "LEFT JOIN ride_feedback f ON f.booking_id = b.booking_id " +
                     "WHERE b.student_id = ? AND b.status = ? AND f.feedback_id IS NULL " +
                     "ORDER BY s.slot_time DESC LIMIT 1";
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, studentId);
            ps.setString(2, Booking.STATUS_COMPLETED);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapRowWithSlot(rs);
                }
            }
        }
        return null;
    }

    /** Total bookings across all students, for the admin dashboard. */
    public int getBookingCount() throws SQLException {
        return getCampusTotalTrips();
    }

    /** Marks a just-created booking as paid for with a redeemed voucher — display/audit only. */
    public void markRewardRedeemed(int bookingId) throws SQLException {
        String sql = "UPDATE bookings SET reward_redeemed = 1 WHERE booking_id = ?";
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, bookingId);
            ps.executeUpdate();
        }
    }

    public int createBooking(int studentId, int slotId, BigDecimal distanceKm, BigDecimal co2SavedKg)
            throws SQLException {
        String sql = "INSERT INTO bookings (student_id, slot_id, distance_km, co2_saved_kg) VALUES (?, ?, ?, ?)";
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setInt(1, studentId);
            ps.setInt(2, slotId);
            ps.setBigDecimal(3, distanceKm);
            ps.setBigDecimal(4, co2SavedKg);
            ps.executeUpdate();
            try (ResultSet keys = ps.getGeneratedKeys()) {
                return keys.next() ? keys.getInt(1) : -1;
            }
        }
    }

    public List<Booking> getBookingsForStudent(int studentId) throws SQLException {
        String sql = "SELECT b.*, s.vehicle_type, s.route, s.slot_time " +
                     "FROM bookings b JOIN vehicle_slots s ON b.slot_id = s.slot_id " +
                     "WHERE b.student_id = ? ORDER BY b.booked_at DESC";
        List<Booking> bookings = new ArrayList<>();
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, studentId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    bookings.add(mapRowWithSlot(rs));
                }
            }
        }
        return bookings;
    }

    public Booking findById(int bookingId) throws SQLException {
        String sql = "SELECT b.*, s.vehicle_type, s.route, s.slot_time " +
                     "FROM bookings b JOIN vehicle_slots s ON b.slot_id = s.slot_id " +
                     "WHERE b.booking_id = ?";
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, bookingId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapRowWithSlot(rs);
                }
            }
        }
        return null;
    }

    /**
     * BOOKED rides whose expected arrival has already passed, for
     * PointsService.reconcile() to settle. Filtering on the computed arrival
     * time happens in Java (via RideTimingUtil) rather than SQL date-math,
     * since the speed-per-vehicle-type assumption already lives there.
     */
    public List<Booking> findSettleableBookings(int studentId) throws SQLException {
        String sql = "SELECT b.*, s.vehicle_type, s.route, s.slot_time " +
                     "FROM bookings b JOIN vehicle_slots s ON b.slot_id = s.slot_id " +
                     "WHERE b.student_id = ? AND b.status = ? ORDER BY s.slot_time ASC";
        List<Booking> settleable = new ArrayList<>();
        long now = System.currentTimeMillis();
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, studentId);
            ps.setString(2, Booking.STATUS_BOOKED);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Booking b = mapRowWithSlot(rs);
                    if (RideTimingUtil.hasArrived(b.getSlotTime(), b.getVehicleType(), b.getDistanceKm(), now)) {
                        settleable.add(b);
                    }
                }
            }
        }
        return settleable;
    }

    /**
     * COMPLETED bookings that were actually treated as a legitimate ride for
     * points purposes — i.e. NOT one that was itself rejected for overlapping
     * an earlier ride. This distinction matters: a booking zeroed out by the
     * daily points cap still really happened and must keep blocking a truly
     * overlapping ride, but one already rejected as an overlap is not good
     * evidence of anything and must not be allowed to chain-reject a THIRD,
     * genuinely non-overlapping booking. excludedReason is matched exactly, so
     * it must be the same literal string PointsService awards zero-point
     * overlap rows with.
     */
    public List<Booking> findLegitimateCompletedBookings(int studentId, String excludedReason) throws SQLException {
        String sql = "SELECT b.*, s.vehicle_type, s.route, s.slot_time " +
                     "FROM bookings b JOIN vehicle_slots s ON b.slot_id = s.slot_id " +
                     "WHERE b.student_id = ? AND b.status = ? " +
                     "AND b.booking_id NOT IN (" +
                     "  SELECT booking_id FROM point_events " +
                     "  WHERE booking_id IS NOT NULL AND reason = ?" +
                     ") ORDER BY s.slot_time ASC";
        List<Booking> legitimate = new ArrayList<>();
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, studentId);
            ps.setString(2, Booking.STATUS_COMPLETED);
            ps.setString(3, excludedReason);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    legitimate.add(mapRowWithSlot(rs));
                }
            }
        }
        return legitimate;
    }

    /** Distinct calendar days (by slot_time) on which a ride was completed, for the streak calculation. */
    public List<LocalDate> getCompletedRideDays(int studentId) throws SQLException {
        String sql = "SELECT DISTINCT DATE(s.slot_time) AS ride_day " +
                     "FROM bookings b JOIN vehicle_slots s ON b.slot_id = s.slot_id " +
                     "WHERE b.student_id = ? AND b.status = ? ORDER BY ride_day ASC";
        List<LocalDate> days = new ArrayList<>();
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, studentId);
            ps.setString(2, Booking.STATUS_COMPLETED);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Date d = rs.getDate("ride_day");
                    days.add(d.toLocalDate());
                }
            }
        }
        return days;
    }

    /**
     * Transitions exactly one BOOKED ride to COMPLETED. The status check in the
     * WHERE clause is what makes a repeated reconcile pass over the same booking
     * harmless — the second call simply updates zero rows.
     */
    public boolean markCompleted(int bookingId) throws SQLException {
        String sql = "UPDATE bookings SET status = ? WHERE booking_id = ? AND status = ?";
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, Booking.STATUS_COMPLETED);
            ps.setInt(2, bookingId);
            ps.setString(3, Booking.STATUS_BOOKED);
            return ps.executeUpdate() == 1;
        }
    }

    /**
     * Best-effort compensating action: if awarding points for a just-completed
     * booking fails partway through (e.g. a transient SQLException), this puts
     * the booking back to BOOKED so it re-enters findSettleableBookings() and
     * the next reconcile() call retries it from scratch — self-healing rather
     * than permanently stranding a COMPLETED booking with missing points.
     */
    public void revertToBooked(int bookingId) throws SQLException {
        String sql = "UPDATE bookings SET status = ? WHERE booking_id = ? AND status = ?";
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, Booking.STATUS_BOOKED);
            ps.setInt(2, bookingId);
            ps.setString(3, Booking.STATUS_COMPLETED);
            ps.executeUpdate();
        }
    }

    /**
     * Cancels a booking, frees its seat back to the slot, and reverses the CO2
     * credit that booking it had immediately added to the student's running
     * total — all as one transaction. That immediate-credit-on-booking design
     * predates cancellation existing at all; now that a booking can be undone,
     * leaving the credit in place would overstate the student's impact figures
     * for a ride that never happened. The WHERE clause requires the booking to
     * still be BOOKED and its departure to still be in the future, so this is a
     * single atomic conditional update, not a separate check-then-act.
     */
    public boolean cancelBooking(int bookingId, int studentId) throws SQLException {
        String cancelSql =
            "UPDATE bookings b JOIN vehicle_slots v ON b.slot_id = v.slot_id " +
            "SET b.status = ?, b.cancelled_at = CURRENT_TIMESTAMP " +
            "WHERE b.booking_id = ? AND b.student_id = ? AND b.status = ? AND v.slot_time > NOW()";

        String releaseSeatSql =
            "UPDATE vehicle_slots v JOIN bookings b ON b.slot_id = v.slot_id " +
            "SET v.booked_count = v.booked_count - 1 " +
            "WHERE b.booking_id = ? AND v.booked_count > 0";

        String reverseCo2Sql =
            "UPDATE students s JOIN bookings b ON b.student_id = s.student_id " +
            "SET s.total_co2_saved_kg = s.total_co2_saved_kg - b.co2_saved_kg " +
            "WHERE b.booking_id = ?";

        Connection con = null;
        try {
            con = DBUtil.getConnection();
            con.setAutoCommit(false);

            boolean cancelled;
            try (PreparedStatement ps = con.prepareStatement(cancelSql)) {
                ps.setString(1, Booking.STATUS_CANCELLED);
                ps.setInt(2, bookingId);
                ps.setInt(3, studentId);
                ps.setString(4, Booking.STATUS_BOOKED);
                cancelled = ps.executeUpdate() == 1;
            }

            if (!cancelled) {
                con.rollback();
                return false;
            }

            try (PreparedStatement ps = con.prepareStatement(releaseSeatSql)) {
                ps.setInt(1, bookingId);
                if (ps.executeUpdate() != 1) {
                    // The status flip succeeded but the seat could not be released
                    // (e.g. booked_count was already 0, which should never happen
                    // given tryReserveSeat's own invariant) — roll back rather than
                    // commit a cancellation with no matching capacity released.
                    con.rollback();
                    return false;
                }
            }

            try (PreparedStatement ps = con.prepareStatement(reverseCo2Sql)) {
                ps.setInt(1, bookingId);
                if (ps.executeUpdate() != 1) {
                    con.rollback();
                    return false;
                }
            }

            con.commit();
            return true;

        } catch (SQLException e) {
            if (con != null) {
                con.rollback();
            }
            throw e;
        } finally {
            if (con != null) {
                con.setAutoCommit(true);
                con.close();
            }
        }
    }

    private Booking mapRowWithSlot(ResultSet rs) throws SQLException {
        Booking b = new Booking();
        b.setBookingId(rs.getInt("booking_id"));
        b.setStudentId(rs.getInt("student_id"));
        b.setSlotId(rs.getInt("slot_id"));
        b.setDistanceKm(rs.getBigDecimal("distance_km"));
        b.setCo2SavedKg(rs.getBigDecimal("co2_saved_kg"));
        b.setStatus(rs.getString("status"));
        b.setBookedAt(rs.getTimestamp("booked_at"));
        b.setCancelledAt(rs.getTimestamp("cancelled_at"));
        b.setRewardRedeemed(rs.getBoolean("reward_redeemed"));
        b.setVehicleType(rs.getString("vehicle_type"));
        b.setRoute(rs.getString("route"));
        b.setSlotTime(rs.getTimestamp("slot_time"));
        return b;
    }
}
