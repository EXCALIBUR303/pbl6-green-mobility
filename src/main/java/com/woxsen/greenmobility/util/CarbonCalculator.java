package com.woxsen.greenmobility.util;

import java.math.BigDecimal;
import java.math.RoundingMode;

/**
 * Estimated CO2 savings = distance x (private-vehicle emission factor - mode's own emission factor).
 * Factors are simplified kg-CO2-per-km figures for a campus-scale demo, not real emissions data.
 */
public class CarbonCalculator {

    private static final BigDecimal PRIVATE_VEHICLE_FACTOR = new BigDecimal("0.192"); // avg petrol car, kg CO2/km
    private static final BigDecimal EV_SHUTTLE_FACTOR = new BigDecimal("0.020");       // shared, grid-charged EV
    private static final BigDecimal SHARED_BIKE_FACTOR = new BigDecimal("0.000");      // zero tailpipe emissions

    public static BigDecimal savedKg(String vehicleType, BigDecimal distanceKm) {
        BigDecimal modeFactor = "Shared Bike".equalsIgnoreCase(vehicleType)
                ? SHARED_BIKE_FACTOR
                : EV_SHUTTLE_FACTOR;
        BigDecimal diff = PRIVATE_VEHICLE_FACTOR.subtract(modeFactor);
        return distanceKm.multiply(diff).setScale(2, RoundingMode.HALF_UP);
    }
}
