package com.woxsen.greenmobility.model;

import java.math.BigDecimal;
import java.sql.Timestamp;

public class Booking {

    /** Mirrors the bookings.status ENUM exactly — plain String constants, not a
     *  Java enum, to match this codebase's existing style for fixed value sets
     *  (see CookieUtil's cookie-name constants). */
    public static final String STATUS_BOOKED = "BOOKED";
    public static final String STATUS_COMPLETED = "COMPLETED";
    public static final String STATUS_CANCELLED = "CANCELLED";
    public static final String STATUS_NO_SHOW = "NO_SHOW";

    private int bookingId;
    private int studentId;
    private int slotId;
    private BigDecimal distanceKm;
    private BigDecimal co2SavedKg;
    private String status;
    private Timestamp bookedAt;
    private Timestamp cancelledAt;

    // Denormalised fields for display on the history page (joined from vehicle_slots)
    private String vehicleType;
    private String route;
    private Timestamp slotTime;

    // UI-only, set by history.jsp after a separate FeedbackDAO.hasFeedback()
    // check — not populated by any DAO mapRow(), same rationale as the
    // vehicleType/route/slotTime denormalisation above.
    private boolean feedbackSubmitted;

    // Real DB column (bookings.reward_redeemed) — true when this booking
    // consumed a rewards-page free-ride voucher instead of a plain points-only
    // booking. Purely a display/audit flag; does not change how the seat was
    // reserved or how CO2/points were credited.
    private boolean rewardRedeemed;

    public Booking() {
    }

    /** True once the ride's window has passed and it wasn't cancelled. */
    public boolean isCompleted() {
        return STATUS_COMPLETED.equals(status);
    }

    public boolean isCancelled() {
        return STATUS_CANCELLED.equals(status);
    }

    /** Only a BOOKED ride, still ahead of its departure, can be cancelled. */
    public boolean isCancellable() {
        return STATUS_BOOKED.equals(status) && slotTime != null
                && slotTime.after(new Timestamp(System.currentTimeMillis()));
    }

    public int getBookingId() {
        return bookingId;
    }

    public void setBookingId(int bookingId) {
        this.bookingId = bookingId;
    }

    public int getStudentId() {
        return studentId;
    }

    public void setStudentId(int studentId) {
        this.studentId = studentId;
    }

    public int getSlotId() {
        return slotId;
    }

    public void setSlotId(int slotId) {
        this.slotId = slotId;
    }

    public BigDecimal getDistanceKm() {
        return distanceKm;
    }

    public void setDistanceKm(BigDecimal distanceKm) {
        this.distanceKm = distanceKm;
    }

    public BigDecimal getCo2SavedKg() {
        return co2SavedKg;
    }

    public void setCo2SavedKg(BigDecimal co2SavedKg) {
        this.co2SavedKg = co2SavedKg;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public Timestamp getBookedAt() {
        return bookedAt;
    }

    public void setBookedAt(Timestamp bookedAt) {
        this.bookedAt = bookedAt;
    }

    public Timestamp getCancelledAt() {
        return cancelledAt;
    }

    public void setCancelledAt(Timestamp cancelledAt) {
        this.cancelledAt = cancelledAt;
    }

    public String getVehicleType() {
        return vehicleType;
    }

    public void setVehicleType(String vehicleType) {
        this.vehicleType = vehicleType;
    }

    public String getRoute() {
        return route;
    }

    public void setRoute(String route) {
        this.route = route;
    }

    public Timestamp getSlotTime() {
        return slotTime;
    }

    public void setSlotTime(Timestamp slotTime) {
        this.slotTime = slotTime;
    }

    public boolean isFeedbackSubmitted() {
        return feedbackSubmitted;
    }

    public void setFeedbackSubmitted(boolean feedbackSubmitted) {
        this.feedbackSubmitted = feedbackSubmitted;
    }

    public boolean isRewardRedeemed() {
        return rewardRedeemed;
    }

    public void setRewardRedeemed(boolean rewardRedeemed) {
        this.rewardRedeemed = rewardRedeemed;
    }
}
