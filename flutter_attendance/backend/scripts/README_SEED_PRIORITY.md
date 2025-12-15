# Attendance Priority Sample Data

This script creates sample workers and attendance records to demonstrate the priority sorting system in the dashboard's "Poor Performers" section.

## What It Creates

### GOOD Priority Workers (3 workers)
- **John Excellent** - Carpenter
- **Sarah Perfect** - Electrician  
- **Mike Reliable** - Plumber

**Characteristics:**
- 95% attendance rate
- Always on time (7:00 - 7:05 AM check-in)
- No absences or late arrivals
- Perfect attendance pattern

### MEDIUM Priority Workers (3 workers)
- **David Average** - Mason
- **Lisa Moderate** - Painter
- **Tom Occasional** - Welder

**Characteristics:**
- 87% attendance rate
- Some late arrivals (25% chance, 8:00 - 9:00 AM)
- Occasional absences (13% of workdays)
- Moderate performance

### HIGH Priority Workers (3 workers)
- **Robert Problem** - Laborer
- **Jane Absent** - Carpenter
- **Chris Late** - Electrician

**Characteristics:**
- 70% attendance rate
- Many late arrivals (50% chance, 8:00 - 10:00 AM)
- Frequent absences (30% of workdays)
- Poor performance requiring attention

## Usage

### Run the Script

```bash
cd attendance-app/flutter_attendance/backend
npm run seed:priority
```

Or directly:

```bash
node scripts/seed_attendance_priority.js
```

## What Happens

1. **Creates Employees**: Creates 9 sample employees if they don't exist
2. **Creates Users**: Creates corresponding user accounts for attendance tracking
3. **Clears Old Data**: Removes any existing attendance records for these workers
4. **Creates Attendance Records**: Generates 30 days of attendance data with patterns matching each priority level

## Data Patterns

### Attendance Records Generated
- **Last 30 days** of attendance data
- **Weekdays only** (skips weekends)
- **Realistic check-in/check-out times**
- **Geographic coordinates** (Singapore area)

### Priority Logic
The script creates data that matches the priority calculation logic:
- **GOOD**: ≥90% attendance, no issues
- **MEDIUM**: 85-89% attendance OR minor issues (late arrivals)
- **HIGH**: <80% attendance OR absent today OR 3+ late arrivals OR 2+ absences

## Viewing Results

After running the script:

1. **Start the backend server** (if not running):
   ```bash
   npm run dev
   ```

2. **Start the admin portal** (if not running):
   ```bash
   cd ../../admin-portal
   npm run dev
   ```

3. **View Dashboard**: Navigate to `http://localhost:3000/dashboard`

4. **Check Poor Performers Section**: You should see workers sorted as:
   - **GOOD** priority workers first (green)
   - **MEDIUM** priority workers next (yellow)
   - **HIGH** priority workers last (red)

## Notes

- The script uses **idempotent** operations - safe to run multiple times
- Existing workers/users are reused if they already exist
- Attendance records are **cleared and recreated** for fresh data
- All workers use password: `worker123` (for testing)

## Troubleshooting

### Error: Cannot find module
Make sure you're in the backend directory:
```bash
cd attendance-app/flutter_attendance/backend
```

### Error: Database connection failed
Check your `.env` file has correct database credentials:
- `DATABASE_URL`
- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`

### No data showing in dashboard
1. Ensure backend server is running
2. Refresh the admin portal page
3. Check browser console for errors
4. Verify database connection is working

## Customization

You can modify the script to:
- Change the number of workers per priority
- Adjust attendance percentages
- Modify check-in time patterns
- Add more realistic scenarios

Edit `scripts/seed_attendance_priority.js` to customize.

