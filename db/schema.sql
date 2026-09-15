-- Campus Green Mobility Booking & Carbon-Savings Tracker
-- Database schema

CREATE DATABASE IF NOT EXISTS green_mobility
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE green_mobility;

DROP TABLE IF EXISTS bookings;
DROP TABLE IF EXISTS vehicle_slots;
DROP TABLE IF EXISTS students;

CREATE TABLE students (
  student_id        INT AUTO_INCREMENT PRIMARY KEY,
  name              VARCHAR(100) NOT NULL,
  email             VARCHAR(150) NOT NULL UNIQUE,
  password          VARCHAR(100) NOT NULL,
  total_co2_saved_kg DECIMAL(10,2) NOT NULL DEFAULT 0
);

CREATE TABLE vehicle_slots (
  slot_id       INT AUTO_INCREMENT PRIMARY KEY,
  vehicle_type  VARCHAR(30)  NOT NULL,      -- 'EV Shuttle' or 'Shared Bike'
  route         VARCHAR(100) NOT NULL,
  slot_time     DATETIME     NOT NULL,
  distance_km   DECIMAL(6,2) NOT NULL,
  capacity      INT          NOT NULL,
  booked_count  INT          NOT NULL DEFAULT 0
);

CREATE TABLE bookings (
  booking_id    INT AUTO_INCREMENT PRIMARY KEY,
  student_id    INT NOT NULL,
  slot_id       INT NOT NULL,
  distance_km   DECIMAL(6,2) NOT NULL,
  co2_saved_kg  DECIMAL(6,2) NOT NULL,
  booked_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (student_id) REFERENCES students(student_id),
  FOREIGN KEY (slot_id) REFERENCES vehicle_slots(slot_id)
);

-- Seed data -----------------------------------------------------------

INSERT INTO students (name, email, password) VALUES
  ('Sid Sood', 'sid@woxsen.edu.in', 'password123'),
  ('Test Student', 'test@woxsen.edu.in', 'test1234');

-- Slot times are relative to whenever this script is run, so a freshly loaded
-- database always has genuinely upcoming departures (the browse page shows a
-- live countdown, which looks broken if the seed data is in the past).
INSERT INTO vehicle_slots (vehicle_type, route, slot_time, distance_km, capacity, booked_count) VALUES
  ('EV Shuttle',  'Academic Block -> Food Court',     NOW() + INTERVAL 40 MINUTE,                     1.2, 15, 0),
  ('Shared Bike', 'Library -> Sports Complex',        CONCAT(CURDATE(), ' 17:00:00'),                 2.0, 10, 0),
  ('Shared Bike', 'Hostel Block B -> Main Gate',      CONCAT(CURDATE(), ' 18:00:00'),                 1.5, 10, 0),
  ('EV Shuttle',  'Hostel Block A -> Academic Block', CONCAT(CURDATE() + INTERVAL 1 DAY, ' 08:00:00'), 3.5, 20, 0),
  ('EV Shuttle',  'Hostel Block A -> Academic Block', CONCAT(CURDATE() + INTERVAL 1 DAY, ' 09:00:00'), 3.5, 20, 0),
  ('EV Shuttle',  'Main Gate -> Hostel Block A',      CONCAT(CURDATE() + INTERVAL 1 DAY, ' 21:00:00'), 4.0, 20, 0);

-- Monthly archive ------------------------------------------------------
-- Snapshot of a student's carbon savings for one calendar month, written
-- when they "close out" the month. students.total_co2_saved_kg is the
-- CURRENT-CYCLE running counter and resets to 0 on close-out; the bookings
-- table remains the permanent record, so nothing is ever lost.

CREATE TABLE IF NOT EXISTS monthly_archives (
  archive_id    INT AUTO_INCREMENT PRIMARY KEY,
  student_id    INT NOT NULL,
  period_year   INT NOT NULL,
  period_month  INT NOT NULL,
  co2_saved_kg  DECIMAL(10,2) NOT NULL,
  trip_count    INT NOT NULL,
  archived_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (student_id) REFERENCES students(student_id),
  UNIQUE KEY uniq_student_period (student_id, period_year, period_month)
);
