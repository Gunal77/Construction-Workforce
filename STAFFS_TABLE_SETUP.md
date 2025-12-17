# Staffs Table Setup Instructions

## Summary of Changes

1. **Fixed Admin Clients Route** - Now fetches real projects, supervisors, and staff data
2. **Created Staffs Table** - New separate table for staffs (migration file created)
3. **Created Admin Staffs Route** - Backend API for managing staffs
4. **Updated Client Stats** - Now calculates real statistics from database

## Steps to Complete Setup

### 1. Run the Migration

Run the migration SQL file to create the `staffs` table:

```sql
-- Run this in your Supabase SQL Editor or PostgreSQL client
-- File: attendance-app/flutter_attendance/backend/migrations/021_create_staffs_table.sql
```

Or execute:
```bash
psql -d your_database -f attendance-app/flutter_attendance/backend/migrations/021_create_staffs_table.sql
```

### 2. Migrate Existing Data (Optional)

If you want to migrate existing employees to the staffs table:

```sql
-- Copy employees to staffs table
INSERT INTO staffs (id, name, email, phone, role, project_id, created_at, updated_at)
SELECT id, name, email, phone, role, project_id, created_at, NOW()
FROM employees
ON CONFLICT (id) DO NOTHING;

-- Update client_user_id for staffs based on their project's client
UPDATE staffs s
SET client_user_id = p.client_user_id
FROM projects p
WHERE s.project_id = p.id AND p.client_user_id IS NOT NULL;
```

### 3. Restart Backend Server

The backend server needs to be restarted to load the new routes:

```bash
cd attendance-app/flutter_attendance/backend
npm start
# or
node server.js
```

### 4. Verify API Endpoints

Test the new endpoints:
- `GET /api/admin/staffs` - List all staffs
- `GET /api/admin/staffs/:id` - Get staff by ID
- `POST /api/admin/staffs` - Create new staff
- `PUT /api/admin/staffs/:id` - Update staff
- `DELETE /api/admin/staffs/:id` - Delete staff

### 5. Frontend Updates

The frontend proxy route is already created at:
- `app/api/proxy/staffs/route.ts`

You can now use this in your frontend components to fetch staffs data.

## What's Fixed

1. **Client Details Page** - Now shows real projects, supervisors, and staff counts
2. **Client Statistics** - Calculates actual counts from database
3. **Separate Staffs Table** - New dedicated table for staff management
4. **API Routes** - Full CRUD operations for staffs

## Next Steps

1. Run the migration SQL
2. Restart the backend server
3. Refresh the admin portal
4. Check client details page - should now show real data

