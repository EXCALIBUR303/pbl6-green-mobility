package com.woxsen.greenmobility.dao;

import com.woxsen.greenmobility.model.Student;
import com.woxsen.greenmobility.util.DBUtil;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.SQLIntegrityConstraintViolationException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

public class StudentDAO {

    /**
     * Self-service signup. Returns the new student, or null if the email is
     * already registered — email is the table's existing UNIQUE constraint, so
     * this is a single INSERT with the duplicate case caught rather than a
     * separate existence check racing against a concurrent signup.
     */
    public Student createStudent(String name, String email, String password) throws SQLException {
        String sql = "INSERT INTO students (name, email, password) VALUES (?, ?, ?)";
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, name);
            ps.setString(2, email);
            ps.setString(3, password);
            ps.executeUpdate();
            try (ResultSet keys = ps.getGeneratedKeys()) {
                if (keys.next()) {
                    return findById(keys.getInt(1));
                }
            }
        } catch (SQLIntegrityConstraintViolationException duplicateEmail) {
            return null;
        }
        return null;
    }

    /** Total non-admin students, for the admin dashboard's headline numbers. */
    public int getStudentCount() throws SQLException {
        String sql = "SELECT COUNT(*) FROM students WHERE is_admin = 0";
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            return rs.next() ? rs.getInt(1) : 0;
        }
    }

    /**
     * Spends 200 points for one free-ride voucher, atomically — the WHERE
     * clause re-checks the balance at the database level so this can't take a
     * student below zero even under a double-click or two racing tabs, the
     * same idiom as SlotDAO.tryReserveSeat.
     */
    public boolean redeemFreeRide(int studentId, int cost) throws SQLException {
        String sql = "UPDATE students SET points_balance = points_balance - ?, " +
                     "free_ride_credits = free_ride_credits + 1 " +
                     "WHERE student_id = ? AND points_balance >= ?";
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, cost);
            ps.setInt(2, studentId);
            ps.setInt(3, cost);
            return ps.executeUpdate() == 1;
        }
    }

    /**
     * Spends one free-ride voucher on a booking that's being placed right now.
     * Same atomic conditional-update idiom: the WHERE clause re-checks the
     * credit count so this can't go negative under a race.
     */
    public boolean consumeFreeRideCredit(int studentId) throws SQLException {
        String sql = "UPDATE students SET free_ride_credits = free_ride_credits - 1 " +
                     "WHERE student_id = ? AND free_ride_credits > 0";
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, studentId);
            return ps.executeUpdate() == 1;
        }
    }

    /** Campus-wide CO2 total, shown on the public login page. */
    public BigDecimal getCampusTotalCo2Saved() throws SQLException {
        String sql = "SELECT COALESCE(SUM(total_co2_saved_kg), 0) FROM students WHERE is_admin = 0";
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            return rs.next() ? rs.getBigDecimal(1) : BigDecimal.ZERO;
        }
    }

    public List<Student> getLeaderboard(int limit) throws SQLException {
        String sql = "SELECT * FROM students WHERE is_admin = 0 ORDER BY total_co2_saved_kg DESC LIMIT ?";
        List<Student> students = new ArrayList<>();
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, limit);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    students.add(mapRow(rs));
                }
            }
        }
        return students;
    }

    public Student authenticate(String email, String password) throws SQLException {
        String sql = "SELECT * FROM students WHERE email = ? AND password = ?";
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, email);
            ps.setString(2, password);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapRow(rs);
                }
            }
        }
        return null;
    }

    public Student findById(int studentId) throws SQLException {
        String sql = "SELECT * FROM students WHERE student_id = ?";
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, studentId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapRow(rs);
                }
            }
        }
        return null;
    }

    public void addCo2Saved(int studentId, BigDecimal amountKg) throws SQLException {
        String sql = "UPDATE students SET total_co2_saved_kg = total_co2_saved_kg + ? WHERE student_id = ?";
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setBigDecimal(1, amountKg);
            ps.setInt(2, studentId);
            ps.executeUpdate();
        }
    }

    public void addPoints(int studentId, int delta) throws SQLException {
        String sql = "UPDATE students SET points_balance = points_balance + ? WHERE student_id = ?";
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, delta);
            ps.setInt(2, studentId);
            ps.executeUpdate();
        }
    }

    public int getPointsBalance(int studentId) throws SQLException {
        String sql = "SELECT points_balance FROM students WHERE student_id = ?";
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, studentId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        }
    }

    public List<Student> getPointsLeaderboard(int limit) throws SQLException {
        String sql = "SELECT * FROM students WHERE is_admin = 0 ORDER BY points_balance DESC LIMIT ?";
        List<Student> students = new ArrayList<>();
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, limit);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    students.add(mapRow(rs));
                }
            }
        }
        return students;
    }

    private Student mapRow(ResultSet rs) throws SQLException {
        Student s = new Student();
        s.setStudentId(rs.getInt("student_id"));
        s.setName(rs.getString("name"));
        s.setEmail(rs.getString("email"));
        s.setPassword(rs.getString("password"));
        s.setTotalCo2SavedKg(rs.getBigDecimal("total_co2_saved_kg"));
        s.setPointsBalance(rs.getInt("points_balance"));
        s.setFreeRideCredits(rs.getInt("free_ride_credits"));
        s.setAdmin(rs.getBoolean("is_admin"));
        return s;
    }
}
