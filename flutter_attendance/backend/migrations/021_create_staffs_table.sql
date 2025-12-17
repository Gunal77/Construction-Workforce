-- Create staffs table (separate from employees)
CREATE TABLE IF NOT EXISTS staffs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  email TEXT UNIQUE,
  phone TEXT,
  role TEXT,
  project_id UUID REFERENCES projects(id) ON DELETE SET NULL,
  client_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for faster lookups
CREATE INDEX IF NOT EXISTS idx_staffs_email ON staffs(email);
CREATE INDEX IF NOT EXISTS idx_staffs_project_id ON staffs(project_id);
CREATE INDEX IF NOT EXISTS idx_staffs_client_user_id ON staffs(client_user_id);

-- Add comment
COMMENT ON TABLE staffs IS 'Staff members assigned to projects and clients';

