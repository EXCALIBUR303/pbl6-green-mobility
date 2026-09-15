-- Migration 003: admin role, rewards redemption, open signup
--
-- Admin reuses the existing students table + login/session mechanism rather
-- than a parallel auth system -- is_admin just changes which dashboard a
-- login lands on and which guard (authGuard vs adminGuard) a page uses.
--
-- Rewards: 200 points buys one free_ride_credits, spent automatically on the
-- student's next booking (see BookingDAO.markRewardRedeemed /
-- processBooking.jsp). There is no monetary cost anywhere in this app to
-- "waive" -- the reward is the credit itself plus the badge on that booking.

USE green_mobility;

SET @col_exists = (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = 'green_mobility' AND TABLE_NAME = 'students' AND COLUMN_NAME = 'is_admin'
);
SET @sql = IF(@col_exists = 0,
  'ALTER TABLE students ADD COLUMN is_admin TINYINT(1) NOT NULL DEFAULT 0',
  'SELECT ''students.is_admin already present, skipping'' AS notice'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col_exists = (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = 'green_mobility' AND TABLE_NAME = 'students' AND COLUMN_NAME = 'free_ride_credits'
);
SET @sql = IF(@col_exists = 0,
  'ALTER TABLE students ADD COLUMN free_ride_credits INT NOT NULL DEFAULT 0',
  'SELECT ''students.free_ride_credits already present, skipping'' AS notice'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col_exists = (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = 'green_mobility' AND TABLE_NAME = 'bookings' AND COLUMN_NAME = 'reward_redeemed'
);
SET @sql = IF(@col_exists = 0,
  'ALTER TABLE bookings ADD COLUMN reward_redeemed TINYINT(1) NOT NULL DEFAULT 0',
  'SELECT ''bookings.reward_redeemed already present, skipping'' AS notice'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @needs_redemption = (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = 'green_mobility' AND TABLE_NAME = 'point_events' AND COLUMN_NAME = 'event_type'
  AND COLUMN_TYPE NOT LIKE '%REDEMPTION%'
);
SET @sql = IF(@needs_redemption = 1,
  'ALTER TABLE point_events MODIFY COLUMN event_type ENUM(''RIDE_BASE'',''CARBON_BONUS'',''STREAK_BONUS'',''REVOCATION'',''REDEMPTION'') NOT NULL',
  'SELECT ''point_events.event_type already has REDEMPTION, skipping'' AS notice'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Seed one admin account for demoing. INSERT IGNORE against the existing
-- UNIQUE(email) makes this idempotent.
INSERT IGNORE INTO students (name, email, password, is_admin)
VALUES ('Campus Admin', 'admin@woxsen.edu.in', 'admin123', 1);
