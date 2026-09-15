-- Extra demo students + booking history so the leaderboard and history
-- pages look realistic for screenshots. Run once against a freshly
-- schema.sql-loaded database (re-running would double-book).

USE green_mobility;

INSERT INTO students (name, email, password) VALUES
  ('Aarav Mehta', 'aarav.mehta@woxsen.edu.in', 'test1234'),
  ('Diya Kapoor', 'diya.kapoor@woxsen.edu.in', 'test1234'),
  ('Rohan Iyer', 'rohan.iyer@woxsen.edu.in', 'test1234'),
  ('Isha Nair', 'isha.nair@woxsen.edu.in', 'test1234'),
  ('Kabir Rao', 'kabir.rao@woxsen.edu.in', 'test1234'),
  ('Meera Joshi', 'meera.joshi@woxsen.edu.in', 'test1234');

-- Bookings: (student email, slot_id, distance_km, co2_saved_kg, booked_at)
-- co2_saved_kg follows CarbonCalculator: EV Shuttle -> distance x 0.172, Shared Bike -> distance x 0.192
INSERT INTO bookings (student_id, slot_id, distance_km, co2_saved_kg, booked_at)
SELECT student_id, 1, 3.50, 0.60, '2026-08-25 08:05:00' FROM students WHERE email = 'rohan.iyer@woxsen.edu.in'
UNION ALL SELECT student_id, 4, 2.00, 0.38, '2026-08-25 17:10:00' FROM students WHERE email = 'rohan.iyer@woxsen.edu.in'
UNION ALL SELECT student_id, 6, 4.00, 0.69, '2026-08-26 21:05:00' FROM students WHERE email = 'rohan.iyer@woxsen.edu.in'
UNION ALL SELECT student_id, 1, 3.50, 0.60, '2026-08-27 08:02:00' FROM students WHERE email = 'rohan.iyer@woxsen.edu.in'
UNION ALL SELECT student_id, 3, 1.20, 0.21, '2026-08-28 12:31:00' FROM students WHERE email = 'rohan.iyer@woxsen.edu.in'

UNION ALL SELECT student_id, 2, 3.50, 0.60, '2026-08-25 09:03:00' FROM students WHERE email = 'diya.kapoor@woxsen.edu.in'
UNION ALL SELECT student_id, 5, 1.50, 0.29, '2026-08-26 18:07:00' FROM students WHERE email = 'diya.kapoor@woxsen.edu.in'
UNION ALL SELECT student_id, 4, 2.00, 0.38, '2026-08-27 17:12:00' FROM students WHERE email = 'diya.kapoor@woxsen.edu.in'
UNION ALL SELECT student_id, 1, 3.50, 0.60, '2026-08-28 08:01:00' FROM students WHERE email = 'diya.kapoor@woxsen.edu.in'

UNION ALL SELECT student_id, 6, 4.00, 0.69, '2026-08-25 21:03:00' FROM students WHERE email = 'aarav.mehta@woxsen.edu.in'
UNION ALL SELECT student_id, 3, 1.20, 0.21, '2026-08-27 12:33:00' FROM students WHERE email = 'aarav.mehta@woxsen.edu.in'
UNION ALL SELECT student_id, 2, 3.50, 0.60, '2026-08-28 09:04:00' FROM students WHERE email = 'aarav.mehta@woxsen.edu.in'

UNION ALL SELECT student_id, 5, 1.50, 0.29, '2026-08-26 18:02:00' FROM students WHERE email = 'isha.nair@woxsen.edu.in'
UNION ALL SELECT student_id, 1, 3.50, 0.60, '2026-08-28 08:03:00' FROM students WHERE email = 'isha.nair@woxsen.edu.in'

UNION ALL SELECT student_id, 4, 2.00, 0.38, '2026-08-27 17:05:00' FROM students WHERE email = 'kabir.rao@woxsen.edu.in'

UNION ALL SELECT student_id, 2, 3.50, 0.60, '2026-08-29 09:01:00' FROM students WHERE email = 'meera.joshi@woxsen.edu.in';

-- Keep vehicle_slots.booked_count and students.total_co2_saved_kg consistent
-- with the bookings we just inserted.
UPDATE vehicle_slots v
SET booked_count = (SELECT COUNT(*) FROM bookings b WHERE b.slot_id = v.slot_id);

UPDATE students s
SET total_co2_saved_kg = (
  SELECT COALESCE(SUM(b.co2_saved_kg), 0) FROM bookings b WHERE b.student_id = s.student_id
);
