-- ============================================
-- Fix Worker Login Credentials
-- Run this to create/update worker users with correct passwords
-- ============================================

-- Step 1: Create users for all employees (if they don't exist)
INSERT INTO users (id, email, password_hash, created_at)
SELECT 
  gen_random_uuid(),
  LOWER(email), -- Ensure lowercase email
  '$2b$12$8P23VIwZRrwTUZL5shUEE.MbToVquXB0HdmFZctDWYHKDfJXUFCXu', -- password: worker123
  NOW()
FROM employees
WHERE LOWER(email) NOT IN (SELECT LOWER(email) FROM users)
ON CONFLICT (email) DO NOTHING;

-- Step 2: Update existing worker user passwords
UPDATE users 
SET password_hash = '$2b$12$8P23VIwZRrwTUZL5shUEE.MbToVquXB0HdmFZctDWYHKDfJXUFCXu'
WHERE LOWER(email) IN (
  SELECT LOWER(email) FROM employees
);

-- Step 3: Verify worker users exist
SELECT '✅ Worker users created/updated!' as message;
SELECT 
  u.email,
  e.name,
  e.role,
  CASE 
    WHEN u.password_hash = '$2b$12$8P23VIwZRrwTUZL5shUEE.MbToVquXB0HdmFZctDWYHKDfJXUFCXu' 
    THEN '✅ Correct password'
    ELSE '❌ Wrong password'
  END as password_status
FROM users u
INNER JOIN employees e ON LOWER(u.email) = LOWER(e.email)
ORDER BY e.name
LIMIT 10;

-- Step 4: Show login credentials
SELECT '🔑 Worker Login Credentials:' as credentials;
SELECT 
  LOWER(e.email) as email,
  'worker123' as password,
  e.name,
  e.role
FROM employees e
INNER JOIN users u ON LOWER(e.email) = LOWER(u.email)
ORDER BY e.name
LIMIT 10;

