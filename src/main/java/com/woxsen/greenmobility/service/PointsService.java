package com.woxsen.greenmobility.service;

import com.woxsen.greenmobility.dao.BookingDAO;
import com.woxsen.greenmobility.dao.PointsDAO;
import com.woxsen.greenmobility.dao.StudentDAO;
import com.woxsen.greenmobility.model.Booking;
import com.woxsen.greenmobility.model.PointEvent;
import com.woxsen.greenmobility.util.RideTimingUtil;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

/**
 * Settles a student's finished rides into points, on read rather than on a
 * schedule. Plain Tomcat has no job scheduler, so instead of a background task
 * marking rides COMPLETED as their windows pass, every page that touches a
 * student's data calls reconcile(studentId) first — the settlement work is
 * cheap (usually zero rows) and fully idempotent, so running it on every
 * request is deliberate, not a shortcut.
 *
 * This is the one piece of new logic that sits above the DAO layer, because it
 * genuinely coordinates three tables (bookings, point_events, students) with
 * business rules (scoring, anti-gaming, streaks) that don't belong inside any
 * single DAO method.
 */
public class PointsService {

    /**
     * Points spent on the Rewards page for one free-ride voucher. Public
     * because it's referenced wherever a voucher changes hands: rewards.jsp
     * (redeem), redeemReward.jsp, and cancelBooking.jsp (refund when a
     * voucher-paid booking is cancelled before the ride happens).
     */
    public static final int REDEMPTION_COST = 200;

    /** Flat points for any completed green ride. */
    private static final int BASE_POINTS_PER_RIDE = 10;

    /** Bonus points = round(co2SavedKg * this) — ties the reward to what the ride actually avoided. */
    private static final BigDecimal CARBON_BONUS_MULTIPLIER = new BigDecimal("20");

    /** Ceiling on RIDE_BASE + CARBON_BONUS earned per calendar ride-day; kills long-route farming. */
    private static final int DAILY_POINTS_CAP = 60;

    private static final int STREAK_SHORT_DAYS = 3;
    private static final int STREAK_SHORT_BONUS = 25;
    private static final int STREAK_LONG_DAYS = 7;
    private static final int STREAK_LONG_BONUS = 50;

    /**
     * Fixed literal, never templated with per-booking detail — used both to
     * record why a ride earned nothing AND, symmetrically, to find and exclude
     * those same bookings later (BookingDAO.findLegitimateCompletedBookings).
     * A ride rejected for overlapping another is not trustworthy evidence of
     * anything and must not itself be allowed to reject a third, genuinely
     * non-overlapping ride — see the overlap-chaining note below.
     */
    private static final String OVERLAP_REASON = "Overlaps another ride already counted";

    private final BookingDAO bookingDAO = new BookingDAO();
    private final PointsDAO pointsDAO = new PointsDAO();
    private final StudentDAO studentDAO = new StudentDAO();

    /**
     * Settles every BOOKED ride of this student's whose expected arrival has
     * passed, then re-checks streak milestones. Safe to call on every page
     * load: a booking already COMPLETED is not in the settleable list at all,
     * and every points award is itself idempotent (see PointsDAO), so calling
     * this twice in a row for the same state is a correct no-op, not a bug.
     */
    public void reconcile(int studentId) throws SQLException {
        List<Booking> settleable = bookingDAO.findSettleableBookings(studentId); // sorted by slot_time ASC
        if (!settleable.isEmpty()) {
            // Seeded from history (past reconcile() calls), then grown as this
            // call settles more rides — but ONLY with rides that were actually
            // treated as legitimate, never one already rejected for overlap.
            List<Booking> legitimateRides =
                    new ArrayList<>(bookingDAO.findLegitimateCompletedBookings(studentId, OVERLAP_REASON));

            for (Booking booking : settleable) {
                settleOneBooking(studentId, booking, legitimateRides);
            }
        }

        updateStreakBonuses(studentId);
    }

    /**
     * Marks one booking COMPLETED and awards it, with a best-effort revert if
     * anything after the status flip throws — findSettleableBookings() only
     * ever returns BOOKED rides, so a booking stuck as COMPLETED with missing
     * point events could otherwise never be retried by a later page load.
     */
    private void settleOneBooking(int studentId, Booking booking, List<Booking> legitimateRides)
            throws SQLException {
        bookingDAO.markCompleted(booking.getBookingId());
        try {
            if (awardForCompletedRide(studentId, booking, legitimateRides)) {
                legitimateRides.add(booking);
            }
        } catch (SQLException e) {
            bookingDAO.revertToBooked(booking.getBookingId());
            throw e;
        }
    }

    /**
     * @return true if this ride was treated as legitimate (not rejected for
     *         overlapping an earlier one) — including when the daily cap
     *         reduced its actual payout to zero, since a cap-limited ride
     *         still really happened and must keep blocking a truly
     *         overlapping one.
     */
    private boolean awardForCompletedRide(int studentId, Booking booking, List<Booking> legitimateRides)
            throws SQLException {

        Timestamp start = booking.getSlotTime();
        Timestamp end = RideTimingUtil.expectedArrival(start, booking.getVehicleType(), booking.getDistanceKm());

        // A student cannot really have taken two overlapping rides. Rather than
        // guess which one is "real", the earlier-departing ride keeps its
        // award and this one is recorded at zero points.
        boolean overlapsALegitimateRide = legitimateRides.stream().anyMatch(other ->
                other.getBookingId() != booking.getBookingId() &&
                RideTimingUtil.overlaps(start, end, other.getSlotTime(),
                        RideTimingUtil.expectedArrival(other.getSlotTime(), other.getVehicleType(), other.getDistanceKm())));

        if (overlapsALegitimateRide) {
            pointsDAO.awardIfAbsent(studentId, booking.getBookingId(), PointEvent.TYPE_RIDE_BASE, 0, OVERLAP_REASON);
            pointsDAO.awardIfAbsent(studentId, booking.getBookingId(), PointEvent.TYPE_CARBON_BONUS, 0, OVERLAP_REASON);
            return false;
        }

        LocalDate rideDay = start.toLocalDateTime().toLocalDate();
        int alreadyEarnedToday = pointsDAO.getPointsEarnedForDay(studentId, rideDay);
        int headroom = Math.max(0, DAILY_POINTS_CAP - alreadyEarnedToday);

        int basePoints = Math.min(BASE_POINTS_PER_RIDE, headroom);
        String baseReason = basePoints < BASE_POINTS_PER_RIDE ? "Completed ride (daily cap reached)" : "Completed ride";
        if (pointsDAO.awardIfAbsent(studentId, booking.getBookingId(), PointEvent.TYPE_RIDE_BASE, basePoints, baseReason)
                && basePoints > 0) {
            studentDAO.addPoints(studentId, basePoints);
        }
        headroom -= basePoints;

        int rawBonus = booking.getCo2SavedKg()
                .multiply(CARBON_BONUS_MULTIPLIER)
                .setScale(0, RoundingMode.HALF_UP)
                .intValue();
        int bonusPoints = Math.min(rawBonus, headroom);
        String bonusReason = bonusPoints < rawBonus ? "Carbon savings bonus (daily cap reached)" : "Carbon savings bonus";
        if (pointsDAO.awardIfAbsent(studentId, booking.getBookingId(), PointEvent.TYPE_CARBON_BONUS, bonusPoints, bonusReason)
                && bonusPoints > 0) {
            studentDAO.addPoints(studentId, bonusPoints);
        }

        return true;
    }

    /**
     * A streak is any run of consecutive calendar days with at least one
     * completed ride — it rewards the habit of riding green, not the payout
     * from any one ride, so it is deliberately independent of the daily cap
     * and the overlap rule above.
     *
     * The milestone key identifying "this streak run" is built from the
     * streak's START date, which stays fixed for as long as the SAME run keeps
     * extending — day 3, 4, 5... of one continuous streak all compute the same
     * start date, so the 3-day bonus fires exactly once for that run. Only
     * when the streak breaks and a new one later begins does a different start
     * date appear, correctly allowing a fresh award. (Keying on the streak's
     * END date instead — which advances every day the streak continues — was
     * caught by adversarial verification as re-awarding the bonus daily.)
     */
    private void updateStreakBonuses(int studentId) throws SQLException {
        List<LocalDate> activeDays = bookingDAO.getCompletedRideDays(studentId); // ascending
        if (activeDays.isEmpty()) {
            return;
        }

        int streak = 1;
        for (int i = activeDays.size() - 1; i > 0; i--) {
            if (activeDays.get(i).minusDays(1).equals(activeDays.get(i - 1))) {
                streak++;
            } else {
                break;
            }
        }
        LocalDate streakStart = activeDays.get(activeDays.size() - streak);

        awardStreakMilestoneIfNew(studentId, streak, STREAK_SHORT_DAYS, STREAK_SHORT_BONUS, streakStart);
        awardStreakMilestoneIfNew(studentId, streak, STREAK_LONG_DAYS, STREAK_LONG_BONUS, streakStart);
    }

    private void awardStreakMilestoneIfNew(int studentId, int streakLength, int milestoneDays, int bonusPoints,
                                            LocalDate streakStart) throws SQLException {
        if (streakLength < milestoneDays) {
            return;
        }
        String milestoneKey = milestoneDays + "d-streak-from-" + streakStart;
        String reason = milestoneDays + "-day streak starting " + streakStart;
        // The UNIQUE(student_id, milestone_key) constraint is the actual gate —
        // this INSERT IGNORE either wins the award or safely no-ops, even under
        // two near-simultaneous requests for the same student.
        if (pointsDAO.awardStreakBonusIfAbsent(studentId, bonusPoints, milestoneKey, reason)) {
            studentDAO.addPoints(studentId, bonusPoints);
        }
    }
}
