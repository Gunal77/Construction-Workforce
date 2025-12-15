-- ============================================
-- Seed Additional GOOD and MEDIUM Performance Sample Data (SQL)
-- 
-- Creates additional sample workers with GOOD and MEDIUM performance levels
-- to provide more variety in the dashboard
-- 
-- Usage: Run this script in Supabase SQL Editor or psql
-- ============================================

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- 1. CREATE ADDITIONAL EMPLOYEES
-- ============================================

-- Additional GOOD Priority Workers (5 more workers)
INSERT INTO employees (id, name, email, role, created_at)
VALUES 
  (gen_random_uuid(), 'Emma Consistent', 'emma.consistent@example.com', 'Foreman', NOW()),
  (gen_random_uuid(), 'James Punctual', 'james.punctual@example.com', 'Crane Operator', NOW()),
  (gen_random_uuid(), 'Maria Dedicated', 'maria.dedicated@example.com', 'Safety Officer', NOW()),
  (gen_random_uuid(), 'Alex Steady', 'alex.steady@example.com', 'Site Engineer', NOW()),
  (gen_random_uuid(), 'Sophia Reliable', 'sophia.reliable@example.com', 'Quality Inspector', NOW())
ON CONFLICT (email) DO NOTHING;

-- Additional MEDIUM Priority Workers (5 more workers)
INSERT INTO employees (id, name, email, role, created_at)
VALUES 
  (gen_random_uuid(), 'Ryan Variable', 'ryan.variable@example.com', 'Concrete Worker', NOW()),
  (gen_random_uuid(), 'Olivia Irregular', 'olivia.irregular@example.com', 'Steel Worker', NOW()),
  (gen_random_uuid(), 'Noah Inconsistent', 'noah.inconsistent@example.com', 'Equipment Operator', NOW()),
  (gen_random_uuid(), 'Ava Moderate', 'ava.moderate@example.com', 'Scaffolder', NOW()),
  (gen_random_uuid(), 'Liam Average', 'liam.average@example.com', 'Roofer', NOW())
ON CONFLICT (email) DO NOTHING;

-- ============================================
-- 2. CREATE USERS (for attendance tracking)
-- ============================================

-- Password hash for 'worker123'
INSERT INTO users (id, email, password_hash, created_at)
SELECT 
  gen_random_uuid(),
  email,
  '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyY5Y5Y5Y5Y5Y', -- worker123
  NOW()
FROM employees
WHERE email IN (
  'emma.consistent@example.com',
  'james.punctual@example.com',
  'maria.dedicated@example.com',
  'alex.steady@example.com',
  'sophia.reliable@example.com',
  'ryan.variable@example.com',
  'olivia.irregular@example.com',
  'noah.inconsistent@example.com',
  'ava.moderate@example.com',
  'liam.average@example.com'
)
ON CONFLICT (email) DO NOTHING;

-- ============================================
-- 3. CLEAR EXISTING ATTENDANCE RECORDS (for these workers only)
-- ============================================

DELETE FROM attendance_logs 
WHERE user_id IN (
  SELECT u.id FROM users u
  WHERE u.email IN (
    'emma.consistent@example.com',
    'james.punctual@example.com',
    'maria.dedicated@example.com',
    'alex.steady@example.com',
    'sophia.reliable@example.com',
    'ryan.variable@example.com',
    'olivia.irregular@example.com',
    'noah.inconsistent@example.com',
    'ava.moderate@example.com',
    'liam.average@example.com'
  )
);

-- ============================================
-- 4. CREATE ATTENDANCE RECORDS
-- ============================================

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
      'emma.consistent@example.com',
      'james.punctual@example.com',
      'maria.dedicated@example.com',
      'alex.steady@example.com',
      'sophia.reliable@example.com',
      'ryan.variable@example.com',
      'olivia.irregular@example.com',
      'noah.inconsistent@example.com',
      'ava.moderate@example.com',
      'liam.average@example.com'
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
      
      -- GOOD Priority Workers: 92-96% attendance, mostly on time
      IF worker_email IN (
        'emma.consistent@example.com',
        'james.punctual@example.com',
        'maria.dedicated@example.com',
        'alex.steady@example.com',
        'sophia.reliable@example.com'
      ) THEN
        -- Different attendance rates for variety
        CASE worker_email
          WHEN 'emma.consistent@example.com' THEN
            -- 96% attendance, always on time
            IF random_val < 0.04 THEN
              should_create := FALSE;
            ELSE
              check_in_minute := floor(random() * 5)::INT; -- 7:00 - 7:05 AM
            END IF;
          WHEN 'james.punctual@example.com' THEN
            -- 95% attendance, always on time
            IF random_val < 0.05 THEN
              should_create := FALSE;
            ELSE
              check_in_minute := floor(random() * 8)::INT; -- 7:00 - 7:08 AM
            END IF;
          WHEN 'maria.dedicated@example.com' THEN
            -- 94% attendance, very rarely late
            IF random_val < 0.06 THEN
              should_create := FALSE;
            ELSIF random_val < 0.08 THEN
              -- 2% chance of being slightly late (7:15 - 7:30 AM)
              check_in_hour := 7;
              check_in_minute := 15 + floor(random() * 16)::INT;
            ELSE
              check_in_minute := floor(random() * 10)::INT; -- 7:00 - 7:10 AM
            END IF;
          WHEN 'alex.steady@example.com' THEN
            -- 93% attendance, mostly on time
            IF random_val < 0.07 THEN
              should_create := FALSE;
            ELSIF random_val < 0.10 THEN
              -- 3% chance of being late (7:20 - 7:45 AM)
              check_in_hour := 7;
              check_in_minute := 20 + floor(random() * 26)::INT;
            ELSE
              check_in_minute := floor(random() * 12)::INT; -- 7:00 - 7:12 AM
            END IF;
          WHEN 'sophia.reliable@example.com' THEN
            -- 92% attendance, good but not perfect
            IF random_val < 0.08 THEN
              should_create := FALSE;
            ELSIF random_val < 0.12 THEN
              -- 4% chance of being late (7:30 - 8:00 AM)
              check_in_hour := 7;
              check_in_minute := 30 + floor(random() * 31)::INT;
            ELSE
              check_in_minute := floor(random() * 15)::INT; -- 7:00 - 7:15 AM
            END IF;
        END CASE;
      
      -- MEDIUM Priority Workers: 80-89% attendance, some late arrivals
      ELSIF worker_email IN (
        'ryan.variable@example.com',
        'olivia.irregular@example.com',
        'noah.inconsistent@example.com',
        'ava.moderate@example.com',
        'liam.average@example.com'
      ) THEN
        -- Different attendance rates for variety
        CASE worker_email
          WHEN 'ryan.variable@example.com' THEN
            -- 89% attendance, occasional late arrivals
            IF random_val < 0.11 THEN
              should_create := FALSE;
            ELSIF random_val < 0.31 THEN
              -- 20% chance of being late (8:00 - 8:30 AM)
              check_in_hour := 8;
              check_in_minute := floor(random() * 31)::INT;
            ELSE
              check_in_minute := floor(random() * 20)::INT; -- 7:00 - 7:20 AM
            END IF;
          WHEN 'olivia.irregular@example.com' THEN
            -- 87% attendance, some late arrivals
            IF random_val < 0.13 THEN
              should_create := FALSE;
            ELSIF random_val < 0.38 THEN
              -- 25% chance of being late (8:00 - 9:00 AM)
              check_in_hour := 8;
              check_in_minute := floor(random() * 60)::INT;
            ELSE
              check_in_minute := floor(random() * 25)::INT; -- 7:00 - 7:25 AM
            END IF;
          WHEN 'noah.inconsistent@example.com' THEN
            -- 85% attendance, frequent late arrivals
            IF random_val < 0.15 THEN
              should_create := FALSE;
            ELSIF random_val < 0.45 THEN
              -- 30% chance of being late (8:00 - 9:30 AM)
              check_in_hour := 8;
              check_in_minute := floor(random() * 90)::INT;
            ELSE
              check_in_minute := floor(random() * 30)::INT; -- 7:00 - 7:30 AM
            END IF;
          WHEN 'ava.moderate@example.com' THEN
            -- 83% attendance, moderate late arrivals
            IF random_val < 0.17 THEN
              should_create := FALSE;
            ELSIF random_val < 0.42 THEN
              -- 25% chance of being late (8:00 - 9:15 AM)
              check_in_hour := 8;
              check_in_minute := floor(random() * 75)::INT;
            ELSE
              check_in_minute := floor(random() * 35)::INT; -- 7:00 - 7:35 AM
            END IF;
          WHEN 'liam.average@example.com' THEN
            -- 80% attendance, many late arrivals
            IF random_val < 0.20 THEN
              should_create := FALSE;
            ELSIF random_val < 0.50 THEN
              -- 30% chance of being late (8:00 - 9:45 AM)
              check_in_hour := 8;
              check_in_minute := floor(random() * 105)::INT;
            ELSE
              check_in_minute := floor(random() * 40)::INT; -- 7:00 - 7:40 AM
            END IF;
        END CASE;
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

-- Show summary of new workers
SELECT 
  e.name,
  e.email,
  e.role,
  COUNT(al.id) as attendance_count,
  COUNT(CASE WHEN DATE(al.check_in_time) = CURRENT_DATE THEN 1 END) as present_today,
  ROUND(COUNT(al.id)::NUMERIC / 22.0 * 100, 1) as attendance_percentage,
  CASE 
    WHEN COUNT(al.id)::NUMERIC / 22.0 * 100 >= 90 THEN 'GOOD'
    WHEN COUNT(al.id)::NUMERIC / 22.0 * 100 >= 80 THEN 'MEDIUM'
    ELSE 'HIGH'
  END as expected_priority
FROM employees e
LEFT JOIN users u ON u.email = e.email
LEFT JOIN attendance_logs al ON al.user_id = u.id AND al.check_in_time >= CURRENT_DATE - INTERVAL '30 days'
WHERE e.email IN (
  'emma.consistent@example.com',
  'james.punctual@example.com',
  'maria.dedicated@example.com',
  'alex.steady@example.com',
  'sophia.reliable@example.com',
  'ryan.variable@example.com',
  'olivia.irregular@example.com',
  'noah.inconsistent@example.com',
  'ava.moderate@example.com',
  'liam.average@example.com'
)
GROUP BY e.id, e.name, e.email, e.role
ORDER BY 
  CASE 
    WHEN e.email LIKE '%.consistent@%' OR e.email LIKE '%.punctual@%' OR e.email LIKE '%.dedicated@%' 
         OR e.email LIKE '%.steady@%' OR e.email LIKE '%.reliable@%' THEN 1
    ELSE 2
  END,
  attendance_percentage DESC;

-- ============================================
-- DONE!
-- ============================================
-- Added 5 GOOD performance workers and 5 MEDIUM performance workers
-- Refresh your dashboard to see the results!

