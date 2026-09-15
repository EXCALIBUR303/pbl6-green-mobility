package com.woxsen.greenmobility.model;

import java.sql.Timestamp;

public class RideFeedback {

    public static final String KIND_POST_RIDE = "POST_RIDE";
    public static final String KIND_CANCELLATION = "CANCELLATION";

    private int feedbackId;
    private int bookingId;
    private int studentId;
    private String kind;

    // Null for a CANCELLATION row — cancelling before a ride happened isn't rated.
    private Integer rating;

    private String category;
    private String comment;
    private Timestamp createdAt;

    // Denormalised for the admin feedback inbox (joined from students) — same
    // rationale as Booking's vehicleType/route/slotTime fields.
    private String studentName;
    private String studentEmail;

    public RideFeedback() {
    }

    public int getFeedbackId() {
        return feedbackId;
    }

    public void setFeedbackId(int feedbackId) {
        this.feedbackId = feedbackId;
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

    public String getKind() {
        return kind;
    }

    public void setKind(String kind) {
        this.kind = kind;
    }

    public Integer getRating() {
        return rating;
    }

    public void setRating(Integer rating) {
        this.rating = rating;
    }

    public String getCategory() {
        return category;
    }

    public void setCategory(String category) {
        this.category = category;
    }

    public String getComment() {
        return comment;
    }

    public void setComment(String comment) {
        this.comment = comment;
    }

    public Timestamp getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Timestamp createdAt) {
        this.createdAt = createdAt;
    }

    public String getStudentName() {
        return studentName;
    }

    public void setStudentName(String studentName) {
        this.studentName = studentName;
    }

    public String getStudentEmail() {
        return studentEmail;
    }

    public void setStudentEmail(String studentEmail) {
        this.studentEmail = studentEmail;
    }
}
