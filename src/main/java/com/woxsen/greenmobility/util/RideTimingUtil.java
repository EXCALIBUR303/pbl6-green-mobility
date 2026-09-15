package com.woxsen.greenmobility.util;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.Timestamp;

/**
 * There is no GPS feed for this project — a ride's expected arrival and
 * overlap with other rides are derived deterministically from the slot's
 * scheduled departure time and an assumed campus travel speed per vehicle
 * type. Stated as an explicit assumption, not hidden behind the maths.
 */
public class RideTimingUtil {

    private static final BigDecimal EV_SHUTTLE_KMH = new BigDecimal("18");
    private static final BigDecimal SHARED_BIKE_KMH = new BigDecimal("12");

    private RideTimingUtil() {
    }

    /** Assumed campus travel speed for a vehicle type, in km/h. */
    public static BigDecimal speedKmh(String vehicleType) {
        return "Shared Bike".equalsIgnoreCase(vehicleType) ? SHARED_BIKE_KMH : EV_SHUTTLE_KMH;
    }

    /** How long the ride is expected to take, at the assumed speed. */
    public static long durationMinutes(String vehicleType, BigDecimal distanceKm) {
        BigDecimal hours = distanceKm.divide(speedKmh(vehicleType), 6, RoundingMode.HALF_UP);
        return hours.multiply(new BigDecimal("60")).setScale(0, RoundingMode.HALF_UP).longValue();
    }

    /** When the ride is expected to arrive, given its scheduled departure. */
    public static Timestamp expectedArrival(Timestamp slotTime, String vehicleType, BigDecimal distanceKm) {
        long durationMs = durationMinutes(vehicleType, distanceKm) * 60_000L;
        return new Timestamp(slotTime.getTime() + durationMs);
    }

    /** True once the ride's expected arrival time has passed. */
    public static boolean hasArrived(Timestamp slotTime, String vehicleType, BigDecimal distanceKm, long nowMs) {
        return expectedArrival(slotTime, vehicleType, distanceKm).getTime() <= nowMs;
    }

    /**
     * Two ride windows overlap if the departure of one is before the arrival of
     * the other and vice versa — the standard interval-intersection test. Used
     * to refuse a points payout for a "ride" a student could not physically have
     * taken because they were already on another one.
     */
    public static boolean overlaps(Timestamp aStart, Timestamp aEnd, Timestamp bStart, Timestamp bEnd) {
        return aStart.getTime() < bEnd.getTime() && bStart.getTime() < aEnd.getTime();
    }
}
