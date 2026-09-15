-- Migration 001: booking lifecycle, points ledger, ride feedback
--
-- Feature extension for PBL6 (points/rewards, live 3D locator, feedback flows).
-- Written as ALTER/CREATE against the live database, deliberately NOT a re-run
-- of schema.sql — the existing bookings/vehicle_slots data (including the
-- staged overbooking-demo slot) must survive this untouched.
--
-- Safe to re-run: every statement is idempotent (IF NOT EXISTS / conditional
-- column add), matching the IF NOT EXISTS style schema.sql already uses for
-- monthly_archives.

USE green_mobility;

-- bookings gets a lifecycle. Existing rows default to BOOKED, which is correct
-- for historical data — nothing retroactively becomes COMPLETED just because
-- this migration ran; that only happens via PointsService.reconcile() the next
-- time each affected student loads a page.
SET @col_exists = (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = 'green_mobility' AND TABLE_NAME = 'bookings' AND COLUMN_NAME = 'status'
);
SET @sql = IF(@col_exists = 0,
  'ALTER TABLE bookings
     ADD COLUMN status ENUM(''BOOKED'',''COMPLETED'',''CANCELLED'',''NO_SHOW'')
       NOT NULL DEFAULT ''BOOKED'' AFTER co2_saved_kg,
     ADD COLUMN cancelled_at DATETIME NULL AFTER booked_at',
  'SELECT ''bookings.status already present, skipping'' AS notice'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- students gets a denormalised points cache, same pattern as the existing
-- total_co2_saved_kg running counter.
SET @col_exists = (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = 'green_mobility' AND TABLE_NAME = 'students' AND COLUMN_NAME = 'points_balance'
);
SET @sql = IF(@col_exists = 0,
  'ALTER TABLE students ADD COLUMN points_balance INT NOT NULL DEFAULT 0',
  'SELECT ''students.points_balance already present, skipping'' AS notice'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Append-only points ledger. Never updated in place, only inserted — a
-- revocation is a compensating negative row, never a destructive UPDATE, so
-- "why do I have N points" is always answerable from this table alone.
--
-- UNIQUE (booking_id, event_type) makes every award idempotent: reconcile()
-- can run on every page load for every student and never double-award the
-- same booking's RIDE_BASE or CARBON_BONUS twice. MySQL permits multiple NULLs
-- in a unique index, so STREAK_BONUS rows (booking_id NULL) are never blocked
-- by each other.
CREATE TABLE IF NOT EXISTS point_events (
  event_id    INT AUTO_INCREMENT PRIMARY KEY,
  student_id  INT NOT NULL,
  booking_id  INT NULL,
  event_type  ENUM('RIDE_BASE','CARBON_BONUS','STREAK_BONUS','REVOCATION') NOT NULL,
  points      INT NOT NULL,
  reason      VARCHAR(120) NOT NULL,
  created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uniq_booking_event (booking_id, event_type),
  FOREIGN KEY (student_id) REFERENCES students(student_id),
  FOREIGN KEY (booking_id) REFERENCES bookings(booking_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- One row per booking's feedback, split by kind rather than two tables, so
-- "areas to improve" is one GROUP BY category across both flows instead of a
-- UNION. UNIQUE (booking_id) makes submission idempotent per booking, and
-- deliberately allows a booking to have EITHER a POST_RIDE or a CANCELLATION
-- row but not both — a cancelled ride was never completed, so a booking can
-- only ever earn one feedback row across its whole lifecycle.
CREATE TABLE IF NOT EXISTS ride_feedback (
  feedback_id INT AUTO_INCREMENT PRIMARY KEY,
  booking_id  INT NOT NULL,
  student_id  INT NOT NULL,
  kind        ENUM('POST_RIDE','CANCELLATION') NOT NULL,
  rating      TINYINT NULL,
  category    VARCHAR(40) NOT NULL,
  comment     TEXT NULL,
  created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uniq_booking_feedback (booking_id),
  FOREIGN KEY (student_id) REFERENCES students(student_id),
  FOREIGN KEY (booking_id) REFERENCES bookings(booking_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
