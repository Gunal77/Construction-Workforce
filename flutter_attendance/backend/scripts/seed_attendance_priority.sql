-- ============================================
-- Seed Attendance Priority Sample Data (SQL)
-- 
-- Creates sample workers and attendance records to demonstrate
-- GOOD, MEDIUM, and HIGH priority performance levels
-- 
-- Usage: Run this script in Supabase SQL Editor or psql
-- ============================================

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- 1. CREATE EMPLOYEES (if they don't exist)
-- ============================================

-- GOOD Priority Workers
INSERT INTO employees (id, name, email, role, created_at)
VALUES 
  (gen_random_uuid(), 'John Excellent', 'john.excellent@example.com', 'Carpenter', NOW()),
  (gen_random_uuid(), 'Sarah Perfect', 'sarah.perfect@example.com', 'Electrician', NOW()),
  (gen_random_uuid(), 'Mike Reliable', 'mike.reliable@example.com', 'Plumber', NOW())
ON CONFLICT (email) DO NOTHING;

-- MEDIUM Priority Workers
INSERT INTO employees (id, name, email, role, created_at)
VALUES 
  (gen_random_uuid(), 'David Average', 'david.average@example.com', 'Mason', NOW()),
  (gen_random_uuid(), 'Lisa Moderate', 'lisa.moderate@example.com', 'Painter', NOW()),
  (gen_random_uuid(), 'Tom Occasional', 'tom.occasional@example.com', 'Welder', NOW())
ON CONFLICT (email) DO NOTHING;

-- HIGH Priority Workers
INSERT INTO employees (id, name, email, role, created_at)
VALUES 
  (gen_random_uuid(), 'Robert Problem', 'robert.problem@example.com', 'Laborer', NOW()),
  (gen_random_uuid(), 'Jane Absent', 'jane.absent@example.com', 'Carpenter', NOW()),
  (gen_random_uuid(), 'Chris Late', 'chris.late@example.com', 'Electrician', NOW())
ON CONFLICT (email) DO NOTHING;

-- ============================================
-- 2. CREATE USERS (for attendance tracking)
-- ============================================

-- Note: Password hash for 'worker123' - you can generate new ones if needed
-- Using bcrypt hash: $2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyY5Y5Y5Y5Y5Y

INSERT INTO users (id, email, password_hash, created_at)
SELECT 
  gen_random_uuid(),
  email,
  '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyY5Y5Y5Y5Y5Y', -- worker123
  NOW()
FROM employees
WHERE email IN (
  'john.excellent@example.com',
  'sarah.perfect@example.com',
  'mike.reliable@example.com',
  'david.average@example.com',
  'lisa.moderate@example.com',
  'tom.occasional@example.com',
  'robert.problem@example.com',
  'jane.absent@example.com',
  'chris.late@example.com'
)
ON CONFLICT (email) DO NOTHING;

-- ============================================
-- 3. CLEAR EXISTING ATTENDANCE RECORDS
-- ============================================

DELETE FROM attendance_logs 
WHERE user_id IN (
  SELECT u.id FROM users u
  WHERE u.email IN (
    'john.excellent@example.com',
    'sarah.perfect@example.com',
    'mike.reliable@example.com',
    'david.average@example.com',
    'lisa.moderate@example.com',
    'tom.occasional@example.com',
    'robert.problem@example.com',
    'jane.absent@example.com',
    'chris.late@example.com'
  )
);

-- ============================================
-- 4. CREATE ATTENDANCE RECORDS
-- ============================================

-- Function to create attendance records for a worker
DO $$
DECLARE
  worker_email TEXT;
  worker_user_id UUID;
  attendance_date DATE;
  check_in_time TIMESTAMPTZ;
  check_out_time TIMESTAMPTZ;
  day_offset INT;
  day_of_week INT;
  expected_check_in_hour INT := 7;
  expected_check_in_minute INT := 0;
  check_in_hour INT;
  check_in_minute INT;
  check_out_hour INT := 17;
  work_hours INT;
  should_create BOOLEAN;
  random_val NUMERIC;
BEGIN
  -- Loop through each worker
  FOR worker_email IN 
    SELECT email FROM employees 
    WHERE email IN (
      'john.excellent@example.com',
      'sarah.perfect@example.com',
      'mike.reliable@example.com',
      'david.average@example.com',
      'lisa.moderate@example.com',
      'tom.occasional@example.com',
      'robert.problem@example.com',
      'jane.absent@example.com',
      'chris.late@example.com'
    )
  LOOP
    -- Get user_id for this worker
    SELECT id INTO worker_user_id FROM users WHERE email = worker_email;
    
    IF worker_user_id IS NULL THEN
      RAISE NOTICE 'User not found for email: %', worker_email;
      CONTINUE;
    END IF;
    
    -- Create attendance for last 30 days
    FOR day_offset IN 0..29 LOOP
      attendance_date := CURRENT_DATE - day_offset;
      day_of_week := EXTRACT(DOW FROM attendance_date);
      
      -- Skip weekends (Saturday = 6, Sunday = 0)
      IF day_of_week = 0 OR day_of_week = 6 THEN
        CONTINUE;
      END IF;
      
      -- Determine attendance pattern based on worker email
      should_create := TRUE;
      check_in_hour := expected_check_in_hour;
      check_in_minute := expected_check_in_minute;
      random_val := random();
      
      -- GOOD Priority: 95% attendance, always on time
      IF worker_email IN ('john.excellent@example.com', 'sarah.perfect@example.com', 'mike.reliable@example.com') THEN
        IF random_val < 0.05 THEN
          -- 5% chance of absence
          should_create := FALSE;
        ELSE
          -- Always on time, slight variation (7:00 - 7:05 AM)
          check_in_minute := floor(random() * 6)::INT;
        END IF;
      
      -- MEDIUM Priority: 87% attendance, some late arrivals
      ELSIF worker_email IN ('david.average@example.com', 'lisa.moderate@example.com', 'tom.occasional@example.com') THEN
        IF random_val < 0.13 THEN
          -- 13% chance of absence
          should_create := FALSE;
        ELSIF random_val < 0.38 THEN
          -- 25% chance of being late (8:00 - 9:00 AM)
          check_in_hour := 8 + floor(random() * 2)::INT;
          check_in_minute := floor(random() * 60)::INT;
        ELSE
          -- On time with slight variation
          check_in_minute := floor(random() * 15)::INT;
        END IF;
      
      -- HIGH Priority: 70% attendance, many late arrivals
      ELSIF worker_email IN ('robert.problem@example.com', 'jane.absent@example.com', 'chris.late@example.com') THEN
        IF random_val < 0.30 THEN
          -- 30% chance of absence
          should_create := FALSE;
        ELSIF random_val < 0.80 THEN
          -- 50% chance of being late (8:00 AM - 10:00 AM)
          check_in_hour := 8 + floor(random() * 3)::INT;
          check_in_minute := floor(random() * 60)::INT;
        ELSE
          -- Sometimes on time
          check_in_minute := floor(random() * 30)::INT;
        END IF;
      END IF;
      
      -- Create attendance record if should_create is true
      IF should_create THEN
        check_in_time := attendance_date + (check_in_hour || ' hours')::INTERVAL + (check_in_minute || ' minutes')::INTERVAL;
        
        -- Check-out time: 4-6 hours after check-in
        work_hours := 4 + floor(random() * 3)::INT;
        check_out_time := check_in_time + (work_hours || ' hours')::INTERVAL;
        
        -- Insert attendance record
        INSERT INTO attendance_logs (id, user_id, check_in_time, check_out_time, latitude, longitude)
        VALUES (
          gen_random_uuid(),
          worker_user_id,
          check_in_time,
          check_out_time,
          1.3521 + (random() - 0.5) * 0.01, -- Singapore area coordinates
          103.8198 + (random() - 0.5) * 0.01
        );
      END IF;
    END LOOP;
    
    RAISE NOTICE 'Created attendance records for: %', worker_email;
  END LOOP;
END $$;

-- ============================================
-- 5. VERIFY DATA
-- ============================================

-- Show summary
SELECT 
  e.name,
  e.email,
  e.role,
  COUNT(al.id) as attendance_count,
  COUNT(CASE WHEN DATE(al.check_in_time) = CURRENT_DATE THEN 1 END) as present_today,
  ROUND(COUNT(al.id)::NUMERIC / 22.0 * 100, 1) as attendance_percentage
FROM employees e
LEFT JOIN users u ON u.email = e.email
LEFT JOIN attendance_logs al ON al.user_id = u.id AND al.check_in_time >= CURRENT_DATE - INTERVAL '30 days'
WHERE e.email IN (
  'john.excellent@example.com',
  'sarah.perfect@example.com',
  'mike.reliable@example.com',
  'david.average@example.com',
  'lisa.moderate@example.com',
  'tom.occasional@example.com',
  'robert.problem@example.com',
  'jane.absent@example.com',
  'chris.late@example.com'
)
GROUP BY e.id, e.name, e.email, e.role
ORDER BY 
  CASE 
    WHEN e.email LIKE '%.excellent@%' OR e.email LIKE '%.perfect@%' OR e.email LIKE '%.reliable@%' THEN 1
    WHEN e.email LIKE '%.average@%' OR e.email LIKE '%.moderate@%' OR e.email LIKE '%.occasional@%' THEN 2
    ELSE 3
  END,
  attendance_percentage DESC;

-- ============================================
-- DONE!
-- ============================================
-- Refresh your dashboard to see the results!
-- Expected order: GOOD → MEDIUM → HIGH

