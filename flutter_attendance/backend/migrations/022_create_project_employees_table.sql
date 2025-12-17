-- Migration: Create project_employees mapping table
-- Purpose: Track employee assignments to projects with historical data

-- Create project_employees table
CREATE TABLE IF NOT EXISTS project_employees (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  assigned_at TIMESTAMPTZ DEFAULT NOW(),
  revoked_at TIMESTAMPTZ,
  assignment_start_date DATE,
  assignment_end_date DATE,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'revoked')),
  assigned_by UUID,
  revoked_by UUID,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_project_employees_project_id ON project_employees(project_id);
CREATE INDEX IF NOT EXISTS idx_project_employees_employee_id ON project_employees(employee_id);
CREATE INDEX IF NOT EXISTS idx_project_employees_status ON project_employees(status);
CREATE INDEX IF NOT EXISTS idx_project_employees_assigned_at ON project_employees(assigned_at);

-- Create unique constraint to prevent duplicate active assignments
CREATE UNIQUE INDEX IF NOT EXISTS idx_project_employees_active_unique 
ON project_employees(project_id, employee_id) 
WHERE status = 'active';

-- Add trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_project_employees_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_project_employees_updated_at
  BEFORE UPDATE ON project_employees
  FOR EACH ROW
  EXECUTE FUNCTION update_project_employees_updated_at();

-- Comment on table and columns
COMMENT ON TABLE project_employees IS 'Mapping table for employee assignments to projects with audit history';
COMMENT ON COLUMN project_employees.status IS 'Current status: active (currently assigned) or revoked (unassigned)';
COMMENT ON COLUMN project_employees.assigned_at IS 'Timestamp when employee was assigned to the project';
COMMENT ON COLUMN project_employees.revoked_at IS 'Timestamp when employee was revoked from the project';
COMMENT ON COLUMN project_employees.assigned_by IS 'User ID of admin who assigned the employee';
COMMENT ON COLUMN project_employees.revoked_by IS 'User ID of admin who revoked the employee';

