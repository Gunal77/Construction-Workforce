-- ============================================
-- Verify Worker Login Setup
-- Run this to check if worker users exist and have correct passwords
-- ============================================

-- Check if users exist for employees
SELECT 
  'Users vs Employees Check' as check_type,
  (SELECT COUNT(*) FROM users) as total_users,
  (SELECT COUNT(*) FROM employees) as total_employees,
  (SELECT COUNT(*) FROM users u 
   INNER JOIN employees e ON LOWER(u.email) = LOWER(e.email)) as matched_users;

-- Show which employees don't have user accounts
SELECT 
  'Missing User Accounts' as issue,
  e.email,
  e.name,
  e.role
FROM employees e
WHERE LOWER(e.email) NOT IN (SELECT LOWER(email) FROM users)
LIMIT 10;

-- Show users with correct password hash
SELECT 
  'Users with Correct Password' as status,
  u.email,
  e.name,
  CASE 
    WHEN u.password_hash = '$2b$12$8P23VIwZRrwTUZL5shUEE.MbToVquXB0HdmFZctDWYHKDfJXUFCXu' 
    THEN '✅ Correct'
    ELSE '❌ Wrong Hash'
  END as password_status
FROM users u
LEFT JOIN employees e ON LOWER(u.email) = LOWER(e.email)
WHERE e.id IS NOT NULL
LIMIT 10;

-- Test login query (simulates what backend does)
SELECT 
  'Test Login Query' as test,
  u.id,
  u.email,
  e.name,
  'worker123' as password_to_test,
  CASE 
    WHEN u.password_hash = '$2b$12$8P23VIwZRrwTUZL5shUEE.MbToVquXB0HdmFZctDWYHKDfJXUFCXu' 
    THEN '✅ Password hash matches worker123'
    ELSE '❌ Password hash does NOT match worker123'
  END as login_status
FROM users u
INNER JOIN employees e ON LOWER(u.email) = LOWER(e.email)
WHERE LOWER(u.email) = 'john.smith@example.com';

