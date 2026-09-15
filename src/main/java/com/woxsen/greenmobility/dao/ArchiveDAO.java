package com.woxsen.greenmobility.dao;

import com.woxsen.greenmobility.model.MonthlySummary;
import com.woxsen.greenmobility.util.DBUtil;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

/**
 * Monthly carbon-savings summaries and the month close-out ("reset").
 */
public class ArchiveDAO {

    /**
     * Per-month totals derived straight from the bookings table. This is the
     * permanent view: closing out a month resets the running counter on
     * students, but never deletes bookings, so these figures always stand.
     */
    public List<MonthlySummary> getMonthlyBreakdown(int studentId) throws SQLException {
        String sql =
            "SELECT YEAR(booked_at) AS period_year, MONTH(booked_at) AS period_month, " +
            "       SUM(co2_saved_kg) AS co2_saved_kg, COUNT(*) AS trip_count " +
            "FROM bookings WHERE student_id = ? " +
            "GROUP BY YEAR(booked_at), MONTH(booked_at) " +
            "ORDER BY period_year DESC, period_month DESC";

        List<MonthlySummary> rows = new ArrayList<>();
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, studentId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    MonthlySummary m = new MonthlySummary();
                    m.setYear(rs.getInt("period_year"));
                    m.setMonth(rs.getInt("period_month"));
                    m.setCo2SavedKg(rs.getBigDecimal("co2_saved_kg"));
                    m.setTripCount(rs.getInt("trip_count"));
                    rows.add(m);
                }
            }
        }

        markArchived(studentId, rows);
        return rows;
    }

    /** Flags which of the derived months have already been closed out. */
    private void markArchived(int studentId, List<MonthlySummary> rows) throws SQLException {
        String sql = "SELECT period_year, period_month FROM monthly_archives WHERE student_id = ?";
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, studentId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    int y = rs.getInt("period_year");
                    int m = rs.getInt("period_month");
                    for (MonthlySummary row : rows) {
                        if (row.getYear() == y && row.getMonth() == m) {
                            row.setArchived(true);
                        }
                    }
                }
            }
        }
    }

    /**
     * Closes out one month: snapshots that month's totals into monthly_archives
     * and zeroes the student's running counter so a fresh cycle starts.
     * Both statements share a transaction — a snapshot without the matching
     * reset (or vice versa) would leave the counter misreporting.
     *
     * @return the archived CO2 figure, or null when the month has no bookings.
     */
    public BigDecimal closeOutMonth(int studentId, int year, int month) throws SQLException {
        String selectSql =
            "SELECT COALESCE(SUM(co2_saved_kg), 0) AS co2, COUNT(*) AS trips " +
            "FROM bookings WHERE student_id = ? AND YEAR(booked_at) = ? AND MONTH(booked_at) = ?";

        // Re-closing the same month refreshes the snapshot rather than failing
        // on the (student_id, year, month) unique key.
        String upsertSql =
            "INSERT INTO monthly_archives (student_id, period_year, period_month, co2_saved_kg, trip_count) " +
            "VALUES (?, ?, ?, ?, ?) " +
            "ON DUPLICATE KEY UPDATE co2_saved_kg = VALUES(co2_saved_kg), " +
            "                        trip_count = VALUES(trip_count), " +
            "                        archived_at = CURRENT_TIMESTAMP";

        String resetSql = "UPDATE students SET total_co2_saved_kg = 0 WHERE student_id = ?";

        Connection con = null;
        try {
            con = DBUtil.getConnection();
            con.setAutoCommit(false);

            BigDecimal co2;
            int trips;
            try (PreparedStatement ps = con.prepareStatement(selectSql)) {
                ps.setInt(1, studentId);
                ps.setInt(2, year);
                ps.setInt(3, month);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) {
                        con.rollback();
                        return null;
                    }
                    co2 = rs.getBigDecimal("co2");
                    trips = rs.getInt("trips");
                }
            }

            if (trips == 0) {
                con.rollback();
                return null;
            }

            try (PreparedStatement ps = con.prepareStatement(upsertSql)) {
                ps.setInt(1, studentId);
                ps.setInt(2, year);
                ps.setInt(3, month);
                ps.setBigDecimal(4, co2);
                ps.setInt(5, trips);
                ps.executeUpdate();
            }

            try (PreparedStatement ps = con.prepareStatement(resetSql)) {
                ps.setInt(1, studentId);
                ps.executeUpdate();
            }

            con.commit();
            return co2;

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
}
