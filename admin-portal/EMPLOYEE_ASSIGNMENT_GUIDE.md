# Employee Assignment & Revocation System

## Overview

The Admin Projects page now includes a comprehensive employee assignment and revocation system. This feature allows administrators to assign employees to projects, track assignment history, and revoke employees when needed.

## Features

### 1. **Assigned Employees Tab**
   - View all employees currently assigned to a project
   - Displays employee name, role/trade, status, and assigned date
   - Real-time updates without page reload

### 2. **Assign Employees**
   - Opens a modal with searchable, paginated employee list
   - Shows employee availability status:
     - **Available**: Employee not assigned to any project
     - **Assigned to Project X**: Employee already assigned to another project
     - **Already Assigned Here**: Employee already assigned to current project
   - Select multiple employees at once
   - Employees assigned to other projects are disabled for selection
   - Pagination support (10 employees per page)
   - Search by name, email, or role

### 3. **Revoke Employee**
   - Click "Revoke" button next to any assigned employee
   - Confirmation dialog to prevent accidental revocation
   - Soft delete - historical data preserved for audit trail
   - Employee becomes immediately available for other projects

### 4. **Business Rules**
   - ✅ An employee can be assigned to only one active project at a time
   - ✅ Admin must revoke before reassigning to another project
   - ✅ Historical assignment data preserved in database
   - ✅ All actions logged with timestamps and admin user info

### 5. **Access Control**
   - **Admin**: Full access to assign and revoke
   - **Supervisor/Staff**: Read-only access (view only)

## Database Schema

### `project_employees` Table

```sql
CREATE TABLE project_employees (
  id UUID PRIMARY KEY,
  project_id UUID REFERENCES projects(id),
  employee_id UUID REFERENCES employees(id),
  assigned_at TIMESTAMPTZ,
  revoked_at TIMESTAMPTZ,
  status TEXT ('active' or 'revoked'),
  assigned_by UUID REFERENCES users(id),
  revoked_by UUID REFERENCES users(id),
  notes TEXT,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
);
```

**Key Features:**
- Unique constraint on `(project_id, employee_id)` where `status = 'active'`
- Soft delete via `status` column (no data loss)
- Audit trail with `assigned_by`, `revoked_by`, timestamps

## API Endpoints

### Backend Routes (`/api/admin/projects/:projectId`)

1. **GET `/employees`**
   - Get all active assigned employees for a project
   - Returns: Array of employees with assignment details

2. **GET `/available-employees?search=&page=&limit=`**
   - Get available employees with assignment status
   - Returns: Paginated employee list with availability info

3. **POST `/employees`**
   - Assign employees to a project
   - Body: `{ employee_ids: string[], notes?: string }`
   - Returns: Assignment results with any errors/warnings

4. **POST `/employees/:employeeId/revoke`**
   - Revoke employee from project
   - Body: `{ notes?: string }`
   - Returns: Updated assignment record

5. **GET `/employees/history`**
   - Get full assignment history (active + revoked)
   - Returns: All assignment records with admin details

### Frontend Proxy Routes

All backend routes are accessible via Next.js proxy:
- `/api/proxy/projects/:id/employees`
- `/api/proxy/projects/:id/available-employees`
- `/api/proxy/projects/:id/employees/:employeeId/revoke`
- `/api/proxy/projects/:id/employees/history`

## Components

### 1. `AssignEmployeesModal.tsx`
**Purpose**: Modal for assigning employees to a project

**Features:**
- Searchable employee list
- Pagination (10 per page)
- Real-time availability status
- Multi-select with checkboxes
- Visual badges (Available, Assigned to X, Already Assigned Here)
- Success/error toast messages

**Props:**
```typescript
interface AssignEmployeesModalProps {
  isOpen: boolean;
  onClose: () => void;
  projectId: string;
  projectName: string;
  onAssignSuccess: () => void;
}
```

### 2. `ConfirmDialog.tsx`
**Purpose**: Reusable confirmation dialog for destructive actions

**Features:**
- Customizable title and message
- Destructive/non-destructive variants
- Loading state support
- Icon support (warning for destructive actions)

**Props:**
```typescript
interface ConfirmDialogProps {
  isOpen: boolean;
  onClose: () => void;
  onConfirm: () => void;
  title: string;
  message: string;
  confirmText?: string;
  cancelText?: string;
  isDestructive?: boolean;
  isLoading?: boolean;
}
```

### 3. `ProjectDetailsModal.tsx` (Enhanced)
**New Tab**: "Assigned Employees"

**Features:**
- Table view of assigned employees
- Assign Employees button (opens modal)
- Individual revoke buttons (with confirmation)
- Real-time updates
- Role-based UI (admin vs read-only)

## Usage Guide

### For Administrators

#### Assigning Employees
1. Navigate to **Admin Portal → Projects**
2. Click on a project card (View icon)
3. Click the **"Assigned Employees"** tab
4. Click **"Assign Employees"** button
5. Search for employees (by name, email, or role)
6. Select one or more available employees
7. Click **"Assign Selected"**
8. Employees are immediately assigned ✅

#### Revoking Employees
1. Open project details → **"Assigned Employees"** tab
2. Locate the employee in the table
3. Click **"Revoke"** button
4. Confirm in the dialog
5. Employee is revoked and becomes available ✅

#### Understanding Employee Status
- **Available** (Green): Not assigned to any project
- **Assigned to Project X** (Yellow): Currently assigned elsewhere (disabled)
- **Already Assigned Here** (Gray): Already on this project (disabled)

### For Supervisors/Staff

- **Read-Only Access**: Can view assigned employees but cannot assign or revoke
- All action buttons are hidden for non-admin users

## Testing

### Manual Testing Checklist

- [ ] **Assign Single Employee**
  - Open project details
  - Assign one available employee
  - Verify employee appears in table
  - Verify employee marked as "Assigned to Project X" in other projects

- [ ] **Assign Multiple Employees**
  - Select 3-5 employees
  - Assign all at once
  - Verify all appear in table

- [ ] **Search Employees**
  - Search by name
  - Search by email
  - Search by role
  - Verify results filter correctly

- [ ] **Pagination**
  - Navigate through pages
  - Verify selected state persists
  - Verify page numbers correct

- [ ] **Revoke Employee**
  - Click revoke on an employee
  - Confirm in dialog
  - Verify employee removed from table
  - Verify employee becomes available again

- [ ] **Prevent Duplicate Assignment**
  - Try to assign employee already on project
  - Verify checkbox is disabled
  - Verify badge shows "Already Assigned Here"

- [ ] **Cross-Project Check**
  - Assign employee to Project A
  - Open Project B
  - Verify employee shows as "Assigned to Project A"
  - Verify cannot assign until revoked

- [ ] **Role-Based Access**
  - Login as Supervisor/Staff
  - Verify no assign/revoke buttons
  - Verify "Read-only view" message

- [ ] **Assignment History**
  - Assign and revoke employees multiple times
  - Check database for historical records
  - Verify `revoked_at` and `revoked_by` populated

## Database Queries

### Check Active Assignments
```sql
SELECT 
  pe.*, 
  e.name as employee_name,
  p.name as project_name,
  u.name as assigned_by_name
FROM project_employees pe
JOIN employees e ON e.id = pe.employee_id
JOIN projects p ON p.id = pe.project_id
LEFT JOIN users u ON u.id = pe.assigned_by
WHERE pe.status = 'active'
ORDER BY pe.assigned_at DESC;
```

### Check Assignment History
```sql
SELECT 
  pe.*,
  e.name as employee_name,
  p.name as project_name,
  u1.name as assigned_by_name,
  u2.name as revoked_by_name
FROM project_employees pe
JOIN employees e ON e.id = pe.employee_id
JOIN projects p ON p.id = pe.project_id
LEFT JOIN users u1 ON u1.id = pe.assigned_by
LEFT JOIN users u2 ON u2.id = pe.revoked_by
ORDER BY pe.assigned_at DESC;
```

### Find Employees Assigned to Multiple Projects (Should be 0)
```sql
SELECT 
  employee_id,
  e.name,
  COUNT(*) as active_projects
FROM project_employees pe
JOIN employees e ON e.id = pe.employee_id
WHERE status = 'active'
GROUP BY employee_id, e.name
HAVING COUNT(*) > 1;
```

## Error Handling

### Backend Validation
- ✅ Project must exist
- ✅ Employee must exist
- ✅ Employee cannot be assigned twice to same project
- ✅ Employee can only be assigned to one active project
- ✅ Only admin can perform actions

### Frontend Validation
- ✅ Must select at least one employee
- ✅ Cannot select employees assigned elsewhere
- ✅ Cannot select employees already on project
- ✅ Success/error toast messages
- ✅ Loading states during async operations

## Troubleshooting

### Employee Not Showing as Available
**Check:**
1. Is employee status 'active' in `project_employees`?
2. Run query: `SELECT * FROM project_employees WHERE employee_id = '<id>' AND status = 'active';`
3. If found, revoke old assignment first

### Assignment Fails
**Common Issues:**
- Employee already assigned to another project
- Missing admin permissions
- Database connection issues
- Check browser console and server logs

### Cannot See Assign/Revoke Buttons
**Check:**
- User role (must be 'admin')
- `isAdmin` prop in ProjectDetailsModal
- Browser localStorage for auth token

## Future Enhancements

- [ ] Bulk revoke (revoke multiple at once)
- [ ] Assignment notifications (email/SMS to employees)
- [ ] Project capacity limits
- [ ] Role-based assignment restrictions
- [ ] Assignment approval workflow
- [ ] Export assignment reports
- [ ] Assignment analytics dashboard

## Files Modified/Created

### Backend
- `migrations/022_create_project_employees_table.sql` ✨ NEW
- `routes/projectEmployees.js` ✨ NEW
- `server.js` (registered new routes)

### Frontend
- `components/AssignEmployeesModal.tsx` ✨ NEW
- `components/ConfirmDialog.tsx` ✨ NEW
- `components/ProjectDetailsModal.tsx` (enhanced)
- `lib/api.ts` (added employee assignment APIs)
- `app/api/proxy/projects/[id]/employees/route.ts` ✨ NEW
- `app/api/proxy/projects/[id]/available-employees/route.ts` ✨ NEW
- `app/api/proxy/projects/[id]/employees/[employeeId]/revoke/route.ts` ✨ NEW
- `app/api/proxy/projects/[id]/employees/history/route.ts` ✨ NEW

## Support

For issues or questions:
1. Check this guide first
2. Review browser console logs
3. Check backend server logs
4. Verify database state with SQL queries above
5. Contact development team

---

**Version**: 1.0.0  
**Last Updated**: December 2024  
**Author**: AI Development Team

