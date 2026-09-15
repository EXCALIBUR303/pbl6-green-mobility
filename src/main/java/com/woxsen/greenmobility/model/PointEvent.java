package com.woxsen.greenmobility.model;

import java.sql.Timestamp;

public class PointEvent {

    public static final String TYPE_RIDE_BASE = "RIDE_BASE";
    public static final String TYPE_CARBON_BONUS = "CARBON_BONUS";
    public static final String TYPE_STREAK_BONUS = "STREAK_BONUS";
    public static final String TYPE_REVOCATION = "REVOCATION";
    public static final String TYPE_REDEMPTION = "REDEMPTION";

    private int eventId;
    private int studentId;

    // Null for STREAK_BONUS rows, which aren't tied to one ride.
    private Integer bookingId;

    private String eventType;
    private int points;
    private String reason;
    private Timestamp createdAt;

    public PointEvent() {
    }

    public int getEventId() {
        return eventId;
    }

    public void setEventId(int eventId) {
        this.eventId = eventId;
    }

    public int getStudentId() {
        return studentId;
    }

    public void setStudentId(int studentId) {
        this.studentId = studentId;
    }

    public Integer getBookingId() {
        return bookingId;
    }

    public void setBookingId(Integer bookingId) {
        this.bookingId = bookingId;
    }

    public String getEventType() {
        return eventType;
    }

    public void setEventType(String eventType) {
        this.eventType = eventType;
    }

    public int getPoints() {
        return points;
    }

    public void setPoints(int points) {
        this.points = points;
    }

    public String getReason() {
        return reason;
    }

    public void setReason(String reason) {
        this.reason = reason;
    }

    public Timestamp getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Timestamp createdAt) {
        this.createdAt = createdAt;
    }
}
