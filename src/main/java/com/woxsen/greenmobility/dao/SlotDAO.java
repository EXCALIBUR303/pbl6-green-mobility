package com.woxsen.greenmobility.dao;

import com.woxsen.greenmobility.model.VehicleSlot;
import com.woxsen.greenmobility.util.CarbonCalculator;
import com.woxsen.greenmobility.util.DBUtil;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;

public class SlotDAO {

    /** Opens a new bookable slot — the admin-panel counterpart to students booking one. */
    public int createSlot(String vehicleType, String route, Timestamp slotTime,
                           BigDecimal distanceKm, int capacity) throws SQLException {
        String sql = "INSERT INTO vehicle_slots (vehicle_type, route, slot_time, distance_km, capacity) " +
                     "VALUES (?, ?, ?, ?, ?)";
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, vehicleType);
            ps.setString(2, route);
            ps.setTimestamp(3, slotTime);
            ps.setBigDecimal(4, distanceKm);
            ps.setInt(5, capacity);
            ps.executeUpdate();
            try (ResultSet keys = ps.getGeneratedKeys()) {
                return keys.next() ? keys.getInt(1) : -1;
            }
        }
    }

    public List<VehicleSlot> getUpcomingSlots() throws SQLException {
        String sql = "SELECT * FROM vehicle_slots ORDER BY slot_time";
        List<VehicleSlot> slots = new ArrayList<>();
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                slots.add(mapRow(rs));
            }
        }
        return slots;
    }

    public VehicleSlot findById(int slotId) throws SQLException {
        String sql = "SELECT * FROM vehicle_slots WHERE slot_id = ?";
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, slotId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapRow(rs);
                }
            }
        }
        return null;
    }

    /**
     * Atomically claims one seat on a slot. The WHERE clause re-checks capacity
     * at the database level so two simultaneous bookings can't both succeed
     * and overbook the slot (the check-then-act race a plain SELECT+UPDATE would allow).
     */
    public boolean tryReserveSeat(int slotId) throws SQLException {
        String sql = "UPDATE vehicle_slots SET booked_count = booked_count + 1 " +
                     "WHERE slot_id = ? AND booked_count < capacity";
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, slotId);
            int rows = ps.executeUpdate();
            return rows == 1;
        }
    }

    private VehicleSlot mapRow(ResultSet rs) throws SQLException {
        VehicleSlot slot = new VehicleSlot();
        slot.setSlotId(rs.getInt("slot_id"));
        slot.setVehicleType(rs.getString("vehicle_type"));
        slot.setRoute(rs.getString("route"));
        slot.setSlotTime(rs.getTimestamp("slot_time"));
        slot.setDistanceKm(rs.getBigDecimal("distance_km"));
        slot.setCapacity(rs.getInt("capacity"));
        slot.setBookedCount(rs.getInt("booked_count"));
        slot.setCo2SavedKg(CarbonCalculator.savedKg(slot.getVehicleType(), slot.getDistanceKm()));
        return slot;
    }
}
