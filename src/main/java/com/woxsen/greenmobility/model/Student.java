package com.woxsen.greenmobility.model;

import java.math.BigDecimal;

public class Student {
    private int studentId;
    private String name;
    private String email;
    private String password;
    private BigDecimal totalCo2SavedKg;
    private int pointsBalance;
    private int freeRideCredits;
    private boolean admin;

    public Student() {
    }

    public int getStudentId() {
        return studentId;
    }

    public void setStudentId(int studentId) {
        this.studentId = studentId;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }

    public BigDecimal getTotalCo2SavedKg() {
        return totalCo2SavedKg;
    }

    public void setTotalCo2SavedKg(BigDecimal totalCo2SavedKg) {
        this.totalCo2SavedKg = totalCo2SavedKg;
    }

    public int getPointsBalance() {
        return pointsBalance;
    }

    public void setPointsBalance(int pointsBalance) {
        this.pointsBalance = pointsBalance;
    }

    public int getFreeRideCredits() {
        return freeRideCredits;
    }

    public void setFreeRideCredits(int freeRideCredits) {
        this.freeRideCredits = freeRideCredits;
    }

    public boolean isAdmin() {
        return admin;
    }

    public void setAdmin(boolean admin) {
        this.admin = admin;
    }
}
