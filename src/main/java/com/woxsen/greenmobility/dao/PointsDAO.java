package com.woxsen.greenmobility.dao;

import com.woxsen.greenmobility.model.PointEvent;
import com.woxsen.greenmobility.util.DBUtil;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

public class PointsDAO {

    /**
     * Awards points for one booking's event exactly once. The unique key on
     * (booking_id, event_type) makes this INSERT IGNORE a no-op on a second
     * reconcile pass over the same booking, so the caller only has to check the
     * return value to know whether the points balance still needs updating —
     * the same "row count tells you what happened" idiom as SlotDAO.tryReserveSeat.
     */
    public boolean awardIfAbsent(int studentId, int bookingId, String eventType, int points, String reason)
            throws SQLException {
        String sql = "INSERT IGNORE INTO point_events (student_id, booking_id, event_type, points, reason) " +
                     "VALUES (?, ?, ?, ?, ?)";
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, studentId);
            ps.setInt(2, bookingId);
            ps.setString(3, eventType);
            ps.setInt(4, points);
            ps.setString(5, reason);
            return ps.executeUpdate() == 1;
        }
    }

    /**
     * Streak bonuses have no booking to key off, so (booking_id, event_type)
     * can't de-duplicate them the way it does ride events — MySQL treats every
     * NULL in a unique index as distinct from every other NULL. milestone_key
     * (backed by UNIQUE(student_id, milestone_key)) exists specifically for
     * this case: unlike a check-then-insert, the database itself is the gate,
     * so two near-simultaneous reconcile() calls (e.g. two browser tabs) can't
     * both win a race and double-award the same milestone. milestoneKey should
     * be built from the streak's stable identity — its START date and length —
     * never from anything that changes while the same streak keeps extending.
     *
     * @return true if this call newly awarded the milestone, false if it was
     *         already recorded (by an earlier call, or a losing concurrent one).
     */
    public boolean awardStreakBonusIfAbsent(int studentId, int points, String milestoneKey, String reason)
            throws SQLException {
        String sql = "INSERT IGNORE INTO point_events " +
                     "(student_id, booking_id, event_type, points, reason, milestone_key) " +
                     "VALUES (?, NULL, ?, ?, ?, ?)";
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, studentId);
            ps.setString(2, PointEvent.TYPE_STREAK_BONUS);
            ps.setInt(3, points);
            ps.setString(4, reason);
            ps.setString(5, milestoneKey);
            return ps.executeUpdate() == 1;
        }
    }

    /**
     * Logs a points-ledger row with no booking behind it — used for reward
     * redemptions (negative points, spent from the balance). Unlike
     * awardIfAbsent/awardStreakBonusIfAbsent this is a plain insert with no
     * idempotency key: it's fired once per explicit button click, not from a
     * reconcile loop that might run the same work twice.
     */
    public void logEvent(int studentId, String eventType, int points, String reason) throws SQLException {
        String sql = "INSERT INTO point_events (student_id, booking_id, event_type, points, reason) " +
                     "VALUES (?, NULL, ?, ?, ?)";
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, studentId);
            ps.setString(2, eventType);
            ps.setInt(3, points);
            ps.setString(4, reason);
            ps.executeUpdate();
        }
    }

    /**
     * Sum of RIDE_BASE + CARBON_BONUS points already earned for rides whose
     * slot_time falls on the given calendar day — the daily cap is enforced
     * against this. Joined through bookings/vehicle_slots because point_events
     * only knows the booking, not the ride's own date.
     */
    public int getPointsEarnedForDay(int studentId, LocalDate day) throws SQLException {
        String sql = "SELECT COALESCE(SUM(pe.points), 0) FROM point_events pe " +
                     "JOIN bookings b ON pe.booking_id = b.booking_id " +
                     "JOIN vehicle_slots v ON b.slot_id = v.slot_id " +
                     "WHERE pe.student_id = ? AND pe.event_type IN (?, ?) " +
                     "AND DATE(v.slot_time) = ?";
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, studentId);
            ps.setString(2, PointEvent.TYPE_RIDE_BASE);
            ps.setString(3, PointEvent.TYPE_CARBON_BONUS);
            ps.setDate(4, java.sql.Date.valueOf(day));
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        }
    }

    public List<PointEvent> getRecentEvents(int studentId, int limit) throws SQLException {
        String sql = "SELECT * FROM point_events WHERE student_id = ? " +
                     "ORDER BY created_at DESC LIMIT ?";
        List<PointEvent> events = new ArrayList<>();
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, studentId);
            ps.setInt(2, limit);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    events.add(mapRow(rs));
                }
            }
        }
        return events;
    }

    private PointEvent mapRow(ResultSet rs) throws SQLException {
        PointEvent e = new PointEvent();
        e.setEventId(rs.getInt("event_id"));
        e.setStudentId(rs.getInt("student_id"));
        int bookingId = rs.getInt("booking_id");
        e.setBookingId(rs.wasNull() ? null : bookingId);
        e.setEventType(rs.getString("event_type"));
        e.setPoints(rs.getInt("points"));
        e.setReason(rs.getString("reason"));
        e.setCreatedAt(rs.getTimestamp("created_at"));
        return e;
    }
}
