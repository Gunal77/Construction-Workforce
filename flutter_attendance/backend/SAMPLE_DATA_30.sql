-- ============================================
-- Sample Data: 30 Employees + Projects + Relations
-- Run this in Supabase SQL Editor
-- ============================================

-- Pre-generated bcrypt hash for password "admin123"
-- Pre-generated bcrypt hash for password "supervisor123" 
-- Pre-generated bcrypt hash for password "worker123"

-- ============================================
-- 1. CREATE ADMIN USER
-- ============================================
INSERT INTO admins (id, name, email, password_hash, phone, created_at, updated_at)
VALUES (
  gen_random_uuid(),
  'Admin User',
  'admin@example.com',
  '$2b$12$V04WE9ohtjfWfGNYW/9gEuzJnDP/bQmJy99ABFpPwd3KFfPTgaiYu', -- password: admin123
  '+1-555-0001',
  NOW(),
  NOW()
)
ON CONFLICT (email) DO UPDATE SET
  name = EXCLUDED.name,
  password_hash = EXCLUDED.password_hash;

-- ============================================
-- 2. CREATE SUPERVISORS (3 supervisors)
-- ============================================
INSERT INTO supervisors (id, name, email, password_hash, phone, created_at, updated_at)
VALUES 
  (gen_random_uuid(), 'John Supervisor', 'supervisor@example.com', '$2b$12$ZBTAPi34YWK1cfenskNkouN8CbESvc70Qkr3g8FIU2h6.gp5ofJzu', '+1-555-1000', NOW(), NOW()),
  (gen_random_uuid(), 'Sarah Manager', 'sarah@example.com', '$2b$12$ZBTAPi34YWK1cfenskNkouN8CbESvc70Qkr3g8FIU2h6.gp5ofJzu', '+1-555-1001', NOW(), NOW()),
  (gen_random_uuid(), 'Mike Foreman', 'mike@example.com', '$2b$12$ZBTAPi34YWK1cfenskNkouN8CbESvc70Qkr3g8FIU2h6.gp5ofJzu', '+1-555-1002', NOW(), NOW())
ON CONFLICT (email) DO UPDATE SET
  name = EXCLUDED.name,
  password_hash = EXCLUDED.password_hash;

-- ============================================
-- 3. CREATE 30 EMPLOYEES (WORKERS)
-- ============================================
INSERT INTO employees (id, name, email, phone, role, created_at)
VALUES 
  (gen_random_uuid(), 'John Smith', 'john.smith@example.com', '+1-555-0101', 'Carpenter', NOW()),
  (gen_random_uuid(), 'Michael Johnson', 'michael.j@example.com', '+1-555-0102', 'Electrician', NOW()),
  (gen_random_uuid(), 'Robert Williams', 'robert.w@example.com', '+1-555-0103', 'Plumber', NOW()),
  (gen_random_uuid(), 'James Brown', 'james.b@example.com', '+1-555-0104', 'Mason', NOW()),
  (gen_random_uuid(), 'David Jones', 'david.j@example.com', '+1-555-0105', 'Painter', NOW()),
  (gen_random_uuid(), 'William Garcia', 'william.g@example.com', '+1-555-0106', 'Welder', NOW()),
  (gen_random_uuid(), 'Richard Miller', 'richard.m@example.com', '+1-555-0107', 'Carpenter', NOW()),
  (gen_random_uuid(), 'Joseph Davis', 'joseph.d@example.com', '+1-555-0108', 'Electrician', NOW()),
  (gen_random_uuid(), 'Thomas Rodriguez', 'thomas.r@example.com', '+1-555-0109', 'Laborer', NOW()),
  (gen_random_uuid(), 'Charles Martinez', 'charles.m@example.com', '+1-555-0110', 'Plumber', NOW()),
  (gen_random_uuid(), 'Christopher Anderson', 'chris.a@example.com', '+1-555-0111', 'Mason', NOW()),
  (gen_random_uuid(), 'Daniel Taylor', 'daniel.t@example.com', '+1-555-0112', 'Carpenter', NOW()),
  (gen_random_uuid(), 'Matthew Thomas', 'matthew.t@example.com', '+1-555-0113', 'Electrician', NOW()),
  (gen_random_uuid(), 'Anthony Hernandez', 'anthony.h@example.com', '+1-555-0114', 'Painter', NOW()),
  (gen_random_uuid(), 'Mark Moore', 'mark.m@example.com', '+1-555-0115', 'Welder', NOW()),
  (gen_random_uuid(), 'Donald Martin', 'donald.m@example.com', '+1-555-0116', 'Laborer', NOW()),
  (gen_random_uuid(), 'Steven Jackson', 'steven.j@example.com', '+1-555-0117', 'Plumber', NOW()),
  (gen_random_uuid(), 'Paul Thompson', 'paul.t@example.com', '+1-555-0118', 'Mason', NOW()),
  (gen_random_uuid(), 'Andrew White', 'andrew.w@example.com', '+1-555-0119', 'Carpenter', NOW()),
  (gen_random_uuid(), 'Joshua Harris', 'joshua.h@example.com', '+1-555-0120', 'Electrician', NOW()),
  (gen_random_uuid(), 'Kevin Clark', 'kevin.c@example.com', '+1-555-0121', 'Plumber', NOW()),
  (gen_random_uuid(), 'Brian Lewis', 'brian.l@example.com', '+1-555-0122', 'Painter', NOW()),
  (gen_random_uuid(), 'George Walker', 'george.w@example.com', '+1-555-0123', 'Welder', NOW()),
  (gen_random_uuid(), 'Edward Hall', 'edward.h@example.com', '+1-555-0124', 'Mason', NOW()),
  (gen_random_uuid(), 'Ronald Allen', 'ronald.a@example.com', '+1-555-0125', 'Carpenter', NOW()),
  (gen_random_uuid(), 'Timothy Young', 'timothy.y@example.com', '+1-555-0126', 'Electrician', NOW()),
  (gen_random_uuid(), 'Jason King', 'jason.k@example.com', '+1-555-0127', 'Plumber', NOW()),
  (gen_random_uuid(), 'Jeffrey Wright', 'jeffrey.w@example.com', '+1-555-0128', 'Laborer', NOW()),
  (gen_random_uuid(), 'Ryan Lopez', 'ryan.l@example.com', '+1-555-0129', 'Painter', NOW()),
  (gen_random_uuid(), 'Jacob Hill', 'jacob.h@example.com', '+1-555-0130', 'Welder', NOW())
ON CONFLICT (email) DO NOTHING;

-- ============================================
-- 4. CREATE 15 PROJECTS
-- ============================================
INSERT INTO projects (id, name, location, start_date, end_date, description, budget, created_at)
VALUES 
  (gen_random_uuid(), 'Downtown Office Complex', '123 Main Street, Downtown', '2024-01-01', '2024-06-30', 'Construction of a 10-story office building', 5000000, NOW()),
  (gen_random_uuid(), 'Residential Apartment Building', '456 Oak Avenue, Midtown', '2024-02-01', '2024-09-30', '5-story residential apartment complex with 50 units', 3500000, NOW()),
  (gen_random_uuid(), 'Shopping Mall Expansion', '789 Commerce Boulevard, Uptown', '2024-01-15', '2024-08-31', 'Expansion of existing shopping mall with new wing', 8000000, NOW()),
  (gen_random_uuid(), 'Hospital Renovation', '321 Medical Drive, Health District', '2024-03-01', '2024-11-30', 'Renovation and expansion of emergency department', 12000000, NOW()),
  (gen_random_uuid(), 'School Building Construction', '654 Education Lane, School District', '2024-02-15', '2024-12-31', 'New elementary school building with 20 classrooms', 4500000, NOW()),
  (gen_random_uuid(), 'Warehouse Facility', '987 Industrial Park, North Side', '2024-01-20', '2024-07-31', 'Large warehouse facility for logistics company', 6000000, NOW()),
  (gen_random_uuid(), 'Parking Garage', '147 Parking Plaza, Downtown', '2024-03-15', '2024-10-31', 'Multi-level parking garage with 500 spaces', 3000000, NOW()),
  (gen_random_uuid(), 'Hotel Construction', '258 Hospitality Road, Tourist Area', '2024-02-01', '2025-01-31', '200-room luxury hotel with conference facilities', 15000000, NOW()),
  (gen_random_uuid(), 'Bridge Rehabilitation', '369 River Crossing, Highway 101', '2024-04-01', '2024-12-31', 'Structural rehabilitation of main bridge', 10000000, NOW()),
  (gen_random_uuid(), 'Retail Store Chain', '741 Shopping Center, Multiple Locations', '2024-02-15', '2024-08-31', 'Construction of 5 new retail stores across city', 4000000, NOW()),
  (gen_random_uuid(), 'Sports Complex', '852 Athletic Avenue, Sports District', '2024-05-01', '2025-03-31', 'Multi-purpose sports complex with indoor/outdoor facilities', 20000000, NOW()),
  (gen_random_uuid(), 'Data Center', '963 Tech Park, Industrial Zone', '2024-03-01', '2024-11-30', 'Secure data center facility with backup power systems', 18000000, NOW()),
  (gen_random_uuid(), 'Senior Living Community', '159 Retirement Road, Residential Area', '2024-04-15', '2025-02-28', 'Senior living facility with 100 units and amenities', 25000000, NOW()),
  (gen_random_uuid(), 'Road Infrastructure Upgrade', '357 Highway Improvement, Major Arteries', '2024-03-20', '2024-12-31', 'Upgrade and expansion of major road network', 15000000, NOW()),
  (gen_random_uuid(), 'Museum Extension', '486 Cultural Boulevard, Arts District', '2024-06-01', '2025-04-30', 'Extension to existing museum with new exhibition halls', 7000000, NOW())
ON CONFLICT DO NOTHING;

-- ============================================
-- 5. ASSIGN WORKERS TO PROJECTS
-- ============================================
-- Assign first 10 workers to first project, next 10 to second project, etc.
DO $$
DECLARE
  project_rec RECORD;
  worker_rec RECORD;
  project_index INT := 0;
  worker_index INT := 0;
BEGIN
  FOR project_rec IN SELECT id FROM projects ORDER BY created_at LIMIT 15
  LOOP
    FOR worker_rec IN SELECT id FROM employees ORDER BY created_at OFFSET (project_index * 2) LIMIT 2
    LOOP
      UPDATE employees 
      SET project_id = project_rec.id 
      WHERE id = worker_rec.id AND project_id IS NULL;
    END LOOP;
    project_index := project_index + 1;
  END LOOP;
END $$;

-- ============================================
-- 6. LINK WORKERS TO SUPERVISORS
-- ============================================
-- Distribute 30 workers among 3 supervisors (10 each)
DO $$
DECLARE
  supervisor_rec RECORD;
  worker_rec RECORD;
  supervisor_index INT := 0;
  workers_per_supervisor INT := 10;
BEGIN
  FOR supervisor_rec IN SELECT id FROM supervisors ORDER BY created_at
  LOOP
    FOR worker_rec IN 
      SELECT id FROM employees 
      ORDER BY created_at 
      OFFSET (supervisor_index * workers_per_supervisor) 
      LIMIT workers_per_supervisor
    LOOP
      INSERT INTO worker_supervisor_relation (worker_id, supervisor_id)
      VALUES (worker_rec.id, supervisor_rec.id)
      ON CONFLICT (worker_id, supervisor_id) DO NOTHING;
    END LOOP;
    supervisor_index := supervisor_index + 1;
  END LOOP;
END $$;

-- ============================================
-- 7. LINK PROJECTS TO SUPERVISORS
-- ============================================
-- Distribute 15 projects among 3 supervisors (5 each)
DO $$
DECLARE
  supervisor_rec RECORD;
  project_rec RECORD;
  supervisor_index INT := 0;
  projects_per_supervisor INT := 5;
BEGIN
  FOR supervisor_rec IN SELECT id FROM supervisors ORDER BY created_at
  LOOP
    FOR project_rec IN 
      SELECT id FROM projects 
      ORDER BY created_at 
      OFFSET (supervisor_index * projects_per_supervisor) 
      LIMIT projects_per_supervisor
    LOOP
      INSERT INTO supervisor_projects_relation (project_id, supervisor_id)
      VALUES (project_rec.id, supervisor_rec.id)
      ON CONFLICT (supervisor_id, project_id) DO NOTHING;
    END LOOP;
    supervisor_index := supervisor_index + 1;
  END LOOP;
END $$;

-- ============================================
-- 8. CREATE WORKER USERS (for attendance app)
-- ============================================
-- Create users for workers to use attendance app
-- Using correct bcrypt hash for all workers (password: worker123)
INSERT INTO users (id, email, password_hash, created_at)
SELECT 
  gen_random_uuid(),
  email,
  '$2b$12$8P23VIwZRrwTUZL5shUEE.MbToVquXB0HdmFZctDWYHKDfJXUFCXu', -- password: worker123
  NOW()
FROM employees
WHERE email NOT IN (SELECT email FROM users)
ON CONFLICT (email) DO NOTHING;

-- ============================================
-- 9. CREATE SAMPLE ATTENDANCE RECORDS (Last 7 days)
-- ============================================
-- Create attendance records for workers for the last 7 days
DO $$
DECLARE
  user_rec RECORD;
  attendance_date DATE;
  check_in_time TIMESTAMPTZ;
  check_out_time TIMESTAMPTZ;
  days_back INT;
BEGIN
  FOR user_rec IN SELECT u.id, u.email FROM users u 
    INNER JOIN employees e ON u.email = e.email 
    ORDER BY e.created_at LIMIT 30
  LOOP
    FOR days_back IN 0..6 LOOP
      attendance_date := CURRENT_DATE - days_back;
      
      -- Skip weekends
      IF EXTRACT(DOW FROM attendance_date) IN (0, 6) THEN
        CONTINUE;
      END IF;
      
      -- Random check-in between 7 AM and 9 AM
      check_in_time := attendance_date + (7 + random() * 2)::int * interval '1 hour' + 
                       (random() * 60)::int * interval '1 minute';
      
      -- Random check-out between 4 PM and 6 PM
      check_out_time := attendance_date + (16 + random() * 2)::int * interval '1 hour' + 
                        (random() * 60)::int * interval '1 minute';
      
      -- Insert attendance record
      INSERT INTO attendance_logs (id, user_id, check_in_time, check_out_time, latitude, longitude)
      VALUES (
        gen_random_uuid(),
        user_rec.id,
        check_in_time,
        check_out_time,
        40.7128 + (random() - 0.5) * 0.01, -- NYC area coordinates with variation
        -74.0060 + (random() - 0.5) * 0.01
      )
      ON CONFLICT DO NOTHING;
    END LOOP;
  END LOOP;
END $$;

-- ============================================
-- 10. CREATE SAMPLE TASKS
-- ============================================
-- Create tasks for workers
DO $$
DECLARE
  worker_rec RECORD;
  supervisor_id_val UUID;
  task_titles TEXT[] := ARRAY[
    'Install electrical wiring',
    'Paint exterior walls',
    'Install plumbing fixtures',
    'Lay foundation concrete',
    'Install windows',
    'Roofing work',
    'Flooring installation',
    'HVAC system setup',
    'Drywall installation',
    'Tile work'
  ];
  task_descriptions TEXT[] := ARRAY[
    'Complete electrical installation for floor 3',
    'Apply primer and paint to building exterior',
    'Install sinks and toilets in bathrooms',
    'Pour and level foundation concrete',
    'Install all windows for building facade',
    'Complete roofing installation',
    'Install tiles and hardwood floors',
    'Install heating and cooling systems',
    'Install and finish drywall',
    'Install ceramic tiles in bathrooms'
  ];
  statuses TEXT[] := ARRAY['pending', 'in_progress', 'completed'];
  task_index INT;
  status_index INT;
  due_date DATE;
  task_status TEXT;
BEGIN
  FOR worker_rec IN SELECT e.id as worker_id, e.project_id 
    FROM employees e 
    WHERE e.project_id IS NOT NULL 
    ORDER BY e.created_at LIMIT 20
  LOOP
    -- Get supervisor for this worker
    SELECT wsr.supervisor_id INTO supervisor_id_val
    FROM worker_supervisor_relation wsr
    WHERE wsr.worker_id = worker_rec.worker_id
    LIMIT 1;
    
    IF supervisor_id_val IS NULL THEN
      CONTINUE;
    END IF;
    
    -- Calculate task index (1-based array indexing, use modulo for safety)
    task_index := (floor(random() * array_length(task_titles, 1))::int % array_length(task_titles, 1)) + 1;
    IF task_index < 1 OR task_index > array_length(task_titles, 1) THEN
      task_index := 1;
    END IF;
    
    -- Calculate due date (7-21 days from now)
    due_date := CURRENT_DATE + (7 + floor(random() * 14)::int);
    
    -- Calculate status index (1-based array indexing, use modulo for safety)
    status_index := (floor(random() * array_length(statuses, 1))::int % array_length(statuses, 1)) + 1;
    IF status_index < 1 OR status_index > array_length(statuses, 1) THEN
      status_index := 1;
    END IF;
    
    -- Get status from array, with fallback
    BEGIN
      task_status := statuses[status_index];
    EXCEPTION WHEN OTHERS THEN
      task_status := 'pending';
    END;
    
    -- Final safety check - ensure task_status is never null
    IF task_status IS NULL OR task_status = '' THEN
      task_status := 'pending';
    END IF;
    
    -- Insert task with all required fields
    INSERT INTO worker_tasks (
      id, project_id, worker_id, supervisor_id, 
      title, description, status, due_date, assigned_at
    )
    VALUES (
      gen_random_uuid(),
      worker_rec.project_id,
      worker_rec.worker_id,
      supervisor_id_val,
      COALESCE(task_titles[task_index], 'General Task'),
      COALESCE(task_descriptions[task_index], 'Task description'),
      COALESCE(task_status, 'pending'),
      due_date,
      NOW()
    )
    ON CONFLICT DO NOTHING;
  END LOOP;
END $$;

-- ============================================
-- SUMMARY
-- ============================================
SELECT '✅ Sample data created successfully!' as message;
SELECT '📊 Summary:' as info;
SELECT COUNT(*) as total_admins FROM admins;
SELECT COUNT(*) as total_supervisors FROM supervisors;
SELECT COUNT(*) as total_employees FROM employees;
SELECT COUNT(*) as total_projects FROM projects;
SELECT COUNT(*) as total_attendance_records FROM attendance_logs;
SELECT COUNT(*) as total_tasks FROM worker_tasks;

SELECT '🔑 Login Credentials:' as credentials;
SELECT 'Admin: admin@example.com / admin123' as admin_login;
SELECT 'Supervisor: supervisor@example.com / supervisor123' as supervisor_login;
SELECT 'Workers: [any employee email] / worker123' as worker_login;

