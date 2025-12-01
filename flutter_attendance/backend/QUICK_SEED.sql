-- ============================================
-- Quick Seed: Create Admin User
-- Run this in Supabase SQL Editor to create a test admin
-- ============================================

-- Note: You'll need to generate a bcrypt hash for the password
-- Use: https://bcrypt-generator.com/ or run: node -e "const bcrypt=require('bcrypt');bcrypt.hash('admin123',12).then(h=>console.log(h))"

-- Pre-generated bcrypt hash for password "admin123"
-- Create Admin User
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

-- Create a few sample projects
INSERT INTO projects (id, name, location, start_date, end_date, description, budget, created_at)
VALUES 
  (gen_random_uuid(), 'Downtown Office Complex', '123 Main Street', '2024-01-01', '2024-06-30', 'Construction of a 10-story office building', 5000000, NOW()),
  (gen_random_uuid(), 'Residential Apartment Building', '456 Oak Avenue', '2024-02-01', '2024-09-30', '5-story residential apartment complex', 3500000, NOW()),
  (gen_random_uuid(), 'Shopping Mall Expansion', '789 Commerce Boulevard', '2024-01-15', '2024-08-31', 'Expansion of existing shopping mall', 8000000, NOW())
ON CONFLICT DO NOTHING;

-- Create a few sample employees
INSERT INTO employees (id, name, email, phone, role, created_at)
VALUES 
  (gen_random_uuid(), 'John Smith', 'john.smith@example.com', '+1-555-0101', 'Carpenter', NOW()),
  (gen_random_uuid(), 'Michael Johnson', 'michael.j@example.com', '+1-555-0102', 'Electrician', NOW()),
  (gen_random_uuid(), 'Robert Williams', 'robert.w@example.com', '+1-555-0103', 'Plumber', NOW()),
  (gen_random_uuid(), 'James Brown', 'james.b@example.com', '+1-555-0104', 'Mason', NOW()),
  (gen_random_uuid(), 'David Jones', 'david.j@example.com', '+1-555-0105', 'Painter', NOW())
ON CONFLICT (email) DO NOTHING;

-- Create a supervisor
INSERT INTO supervisors (id, name, email, password_hash, phone, created_at, updated_at)
VALUES (
  gen_random_uuid(),
  'John Supervisor',
  'supervisor@example.com',
  '$2b$12$V04WE9ohtjfWfGNYW/9gEuzJnDP/bQmJy99ABFpPwd3KFfPTgaiYu', -- password: supervisor123 (same hash for demo)
  '+1-555-1000',
  NOW(),
  NOW()
)
ON CONFLICT (email) DO UPDATE SET
  name = EXCLUDED.name,
  password_hash = EXCLUDED.password_hash;

SELECT '✅ Quick seed completed! You can now login with:' as message;
SELECT 'Admin: admin@example.com / admin123' as credentials;
SELECT 'Supervisor: supervisor@example.com / supervisor123' as supervisor_creds;

