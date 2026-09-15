package com.woxsen.greenmobility.model;

import java.math.BigDecimal;
import java.sql.Timestamp;

public class VehicleSlot {
    private int slotId;
    private String vehicleType;
    private String route;
    private Timestamp slotTime;
    private BigDecimal distanceKm;
    private int capacity;
    private int bookedCount;

    // Derived, not a DB column: filled in by SlotDAO via CarbonCalculator so the
    // browse page can show the payoff of a slot before the student books it.
    private BigDecimal co2SavedKg;

    public VehicleSlot() {
    }

    public BigDecimal getCo2SavedKg() {
        return co2SavedKg;
    }

    public void setCo2SavedKg(BigDecimal co2SavedKg) {
        this.co2SavedKg = co2SavedKg;
    }

    /** Percentage of seats taken — drives the capacity bar on the browse page. */
    public int getFillPercent() {
        if (capacity <= 0) {
            return 100;
        }
        return (int) Math.round((bookedCount * 100.0) / capacity);
    }

    /** True when only a couple of seats remain, so the UI can warn the student. */
    public boolean isAlmostFull() {
        int left = getRemainingCapacity();
        return left > 0 && left <= 2;
    }

    public int getSlotId() {
        return slotId;
    }

    public void setSlotId(int slotId) {
        this.slotId = slotId;
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

    public BigDecimal getDistanceKm() {
        return distanceKm;
    }

    public void setDistanceKm(BigDecimal distanceKm) {
        this.distanceKm = distanceKm;
    }

    public int getCapacity() {
        return capacity;
    }

    public void setCapacity(int capacity) {
        this.capacity = capacity;
    }

    public int getBookedCount() {
        return bookedCount;
    }

    public void setBookedCount(int bookedCount) {
        this.bookedCount = bookedCount;
    }

    public int getRemainingCapacity() {
        return capacity - bookedCount;
    }

    public boolean isFull() {
        return getRemainingCapacity() <= 0;
    }
}
