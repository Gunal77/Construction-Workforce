-- ============================================
-- Fix Supervisor Login Credentials
-- Run this to update supervisor passwords with correct bcrypt hash
-- ============================================

-- Update supervisor passwords with correct bcrypt hash for "supervisor123"
UPDATE supervisors 
SET password_hash = '$2b$12$ZBTAPi34YWK1cfenskNkouN8CbESvc70Qkr3g8FIU2h6.gp5ofJzu'
WHERE email IN ('supervisor@example.com', 'sarah@example.com', 'mike@example.com');

-- Update worker user passwords with correct bcrypt hash for "worker123"
UPDATE users 
SET password_hash = '$2b$12$8P23VIwZRrwTUZL5shUEE.MbToVquXB0HdmFZctDWYHKDfJXUFCXu'
WHERE email IN (
  SELECT email FROM employees
);

-- Verify the updates
SELECT '✅ Supervisor passwords updated!' as message;
SELECT email, name FROM supervisors WHERE email IN ('supervisor@example.com', 'sarah@example.com', 'mike@example.com');

SELECT '✅ Worker passwords updated!' as message;
SELECT COUNT(*) as updated_workers FROM users WHERE password_hash = '$2b$12$8P23VIwZRrwTUZL5shUEE.MbToVquXB0HdmFZctDWYHKDfJXUFCXu';

SELECT '🔑 Login Credentials:' as credentials;
SELECT 'Supervisor: supervisor@example.com / supervisor123' as supervisor_login;
SELECT 'Workers: [any employee email] / worker123' as worker_login;

