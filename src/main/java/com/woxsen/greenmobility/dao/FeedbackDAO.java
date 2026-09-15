package com.woxsen.greenmobility.dao;

import com.woxsen.greenmobility.model.RideFeedback;
import com.woxsen.greenmobility.util.DBUtil;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.util.ArrayList;
import java.util.List;

public class FeedbackDAO {

    /**
     * One feedback row per booking, enforced by the unique key on booking_id —
     * this INSERT IGNORE makes a resubmitted form (double-click, back-button)
     * harmless rather than a constraint-violation error page.
     *
     * @return true if this call actually recorded the feedback, false if the
     *         booking already had a feedback row.
     */
    public boolean submitFeedback(int bookingId, int studentId, String kind, Integer rating,
                                   String category, String comment) throws SQLException {
        // ride_feedback.category is NOT NULL; failing fast here with a clear message
        // beats letting a missing form field surface as an opaque SQLException.
        if (category == null || category.isBlank()) {
            throw new IllegalArgumentException("category is required for ride feedback");
        }

        String sql = "INSERT IGNORE INTO ride_feedback (booking_id, student_id, kind, rating, category, comment) " +
                     "VALUES (?, ?, ?, ?, ?, ?)";
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, bookingId);
            ps.setInt(2, studentId);
            ps.setString(3, kind);
            if (rating != null) {
                ps.setInt(4, rating);
            } else {
                ps.setNull(4, Types.TINYINT);
            }
            ps.setString(5, category);
            ps.setString(6, comment);
            return ps.executeUpdate() == 1;
        }
    }

    /**
     * Every individual feedback row, newest first, with the student's name and
     * email joined in — the admin inbox this feeds is the "sent to admin's
     * login" counterpart to getAreasToImprove()'s anonymous campus-wide
     * aggregate, which stays visible to students too.
     */
    public List<RideFeedback> getAllFeedback() throws SQLException {
        String sql = "SELECT f.*, st.name AS student_name, st.email AS student_email " +
                     "FROM ride_feedback f JOIN students st ON f.student_id = st.student_id " +
                     "ORDER BY f.created_at DESC";
        List<RideFeedback> rows = new ArrayList<>();
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                RideFeedback f = new RideFeedback();
                f.setFeedbackId(rs.getInt("feedback_id"));
                f.setBookingId(rs.getInt("booking_id"));
                f.setStudentId(rs.getInt("student_id"));
                f.setKind(rs.getString("kind"));
                int rating = rs.getInt("rating");
                f.setRating(rs.wasNull() ? null : rating);
                f.setCategory(rs.getString("category"));
                f.setComment(rs.getString("comment"));
                f.setCreatedAt(rs.getTimestamp("created_at"));
                f.setStudentName(rs.getString("student_name"));
                f.setStudentEmail(rs.getString("student_email"));
                rows.add(f);
            }
        }
        return rows;
    }

    /** Total feedback rows, for the admin dashboard. */
    public int getFeedbackCount() throws SQLException {
        String sql = "SELECT COUNT(*) FROM ride_feedback";
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            return rs.next() ? rs.getInt(1) : 0;
        }
    }

    public boolean hasFeedback(int bookingId) throws SQLException {
        String sql = "SELECT 1 FROM ride_feedback WHERE booking_id = ?";
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, bookingId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    /**
     * Campus-wide "areas to improve" signal both feedback flows feed into: one
     * GROUP BY across POST_RIDE and CANCELLATION rows together, ranked by how
     * often each category comes up. AVG(rating) is only meaningful for
     * POST_RIDE rows (CANCELLATION rows have a NULL rating, which AVG ignores).
     */
    public List<CategorySignal> getAreasToImprove() throws SQLException {
        String sql = "SELECT category, COUNT(*) AS mentions, AVG(rating) AS avg_rating " +
                     "FROM ride_feedback GROUP BY category ORDER BY mentions DESC";
        List<CategorySignal> rows = new ArrayList<>();
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                CategorySignal c = new CategorySignal();
                c.setCategory(rs.getString("category"));
                c.setMentions(rs.getInt("mentions"));
                c.setAvgRating(rs.getBigDecimal("avg_rating")); // null if every row was a CANCELLATION
                rows.add(c);
            }
        }
        return rows;
    }

    /**
     * Small read-model for the aggregate query above, not a persisted entity —
     * still a proper JavaBean (private fields, get/set pairs) because JSP's EL
     * resolver reaches values via getters, not public field access.
     */
    public static class CategorySignal {
        private String category;
        private int mentions;
        private java.math.BigDecimal avgRating;

        public String getCategory() {
            return category;
        }

        public void setCategory(String category) {
            this.category = category;
        }

        public int getMentions() {
            return mentions;
        }

        public void setMentions(int mentions) {
            this.mentions = mentions;
        }

        public java.math.BigDecimal getAvgRating() {
            return avgRating;
        }

        public void setAvgRating(java.math.BigDecimal avgRating) {
            this.avgRating = avgRating;
        }
    }
}
