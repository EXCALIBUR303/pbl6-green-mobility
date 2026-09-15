-- Migration 002: give streak bonuses a real database-enforced idempotency key
--
-- The original design used a check-then-insert (hasStreakBonus() then
-- insertStreakBonus()) for streak milestones, reasoning that point_events'
-- UNIQUE(booking_id, event_type) couldn't cover them since booking_id is NULL
-- for a streak row and MySQL does not deduplicate NULLs against each other.
-- Adversarial verification correctly flagged that check-then-insert as a real
-- race: two near-simultaneous requests (e.g. two browser tabs) can both pass
-- the check before either commits, double-awarding the same milestone.
--
-- Fix: a dedicated nullable column that IS unique per (student, milestone),
-- while staying NULL (and therefore non-colliding) for every RIDE_BASE/
-- CARBON_BONUS/REVOCATION row, which don't use it at all.

USE green_mobility;

SET @col_exists = (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = 'green_mobility' AND TABLE_NAME = 'point_events' AND COLUMN_NAME = 'milestone_key'
);
SET @sql = IF(@col_exists = 0,
  'ALTER TABLE point_events
     ADD COLUMN milestone_key VARCHAR(100) NULL AFTER reason,
     ADD UNIQUE KEY uniq_milestone (student_id, milestone_key)',
  'SELECT ''point_events.milestone_key already present, skipping'' AS notice'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
