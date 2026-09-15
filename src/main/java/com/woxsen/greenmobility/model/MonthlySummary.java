package com.woxsen.greenmobility.model;

import java.math.BigDecimal;
import java.time.Month;
import java.time.format.TextStyle;
import java.util.Locale;

/**
 * One calendar month of a student's carbon savings, derived from the bookings
 * table. Also used to render rows archived in monthly_archives.
 */
public class MonthlySummary {

    private int year;
    private int month;               // 1-12
    private BigDecimal co2SavedKg;
    private int tripCount;
    private boolean archived;

    public MonthlySummary() {
    }

    public int getYear() {
        return year;
    }

    public void setYear(int year) {
        this.year = year;
    }

    public int getMonth() {
        return month;
    }

    public void setMonth(int month) {
        this.month = month;
    }

    public BigDecimal getCo2SavedKg() {
        return co2SavedKg;
    }

    public void setCo2SavedKg(BigDecimal co2SavedKg) {
        this.co2SavedKg = co2SavedKg;
    }

    public int getTripCount() {
        return tripCount;
    }

    public void setTripCount(int tripCount) {
        this.tripCount = tripCount;
    }

    public boolean isArchived() {
        return archived;
    }

    public void setArchived(boolean archived) {
        this.archived = archived;
    }

    /** e.g. "August 2026" — for display on the summary page. */
    public String getLabel() {
        return Month.of(month).getDisplayName(TextStyle.FULL, Locale.ENGLISH) + " " + year;
    }
}
