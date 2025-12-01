-- ============================================
-- Assign All Supervisors to All Projects
-- ============================================
-- This SQL script assigns every supervisor to every project
-- in the supervisor_projects_relation table.
--
-- Usage: Run this script in your Supabase SQL Editor or PostgreSQL client
-- ============================================

-- Insert all supervisor-project combinations
-- ON CONFLICT ensures we don't create duplicates
INSERT INTO supervisor_projects_relation (supervisor_id, project_id)
SELECT 
    s.id AS supervisor_id,
    p.id AS project_id
FROM supervisors s
CROSS JOIN projects p
ON CONFLICT (supervisor_id, project_id) DO NOTHING;

-- Show summary
SELECT 
    COUNT(*) AS total_assignments,
    COUNT(DISTINCT supervisor_id) AS unique_supervisors,
    COUNT(DISTINCT project_id) AS unique_projects
FROM supervisor_projects_relation;

-- Show detailed breakdown
SELECT 
    s.name AS supervisor_name,
    s.email AS supervisor_email,
    COUNT(spr.project_id) AS assigned_projects_count
FROM supervisors s
LEFT JOIN supervisor_projects_relation spr ON s.id = spr.supervisor_id
GROUP BY s.id, s.name, s.email
ORDER BY s.name;

