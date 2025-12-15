# Additional GOOD and MEDIUM Performance Sample Data

This script creates additional sample workers with GOOD and MEDIUM performance levels to provide more variety in the dashboard's Performance Overview section.

## What It Creates

### Additional GOOD Priority Workers (5 workers)
- **Emma Consistent** - Foreman (96% attendance, always on time)
- **James Punctual** - Crane Operator (95% attendance, always on time)
- **Maria Dedicated** - Safety Officer (94% attendance, very rarely late)
- **Alex Steady** - Site Engineer (93% attendance, mostly on time)
- **Sophia Reliable** - Quality Inspector (92% attendance, good but not perfect)

**Characteristics:**
- 92-96% attendance rate
- Mostly on time (7:00 - 7:40 AM check-in)
- Very few late arrivals
- Excellent performance pattern

### Additional MEDIUM Priority Workers (5 workers)
- **Ryan Variable** - Concrete Worker (89% attendance, occasional late arrivals)
- **Olivia Irregular** - Steel Worker (87% attendance, some late arrivals)
- **Noah Inconsistent** - Equipment Operator (85% attendance, frequent late arrivals)
- **Ava Moderate** - Scaffolder (83% attendance, moderate late arrivals)
- **Liam Average** - Roofer (80% attendance, many late arrivals)

**Characteristics:**
- 80-89% attendance rate
- Some late arrivals (8:00 - 9:45 AM)
- Occasional absences (11-20% of workdays)
- Moderate performance requiring monitoring

## Usage

### Option 1: Run SQL Script Directly

Copy and paste the SQL script into your Supabase SQL Editor or run with psql:

```bash
cd attendance-app/flutter_attendance/backend
psql $DATABASE_URL -f scripts/seed_good_medium_performance.sql
```

### Option 2: Run Node.js Script

```bash
cd attendance-app/flutter_attendance/backend
npm run seed:good-medium
```

Or directly:

```bash
node scripts/run_good_medium_seed.js
```

## What Happens

1. **Creates Employees**: Creates 10 additional sample employees (5 GOOD, 5 MEDIUM)
2. **Creates Users**: Creates corresponding user accounts for attendance tracking
3. **Clears Old Data**: Removes any existing attendance records for these workers (if they exist)
4. **Creates Attendance Records**: Generates 30 days of attendance data with patterns matching each performance level

## Data Patterns

### Attendance Records Generated
- **Last 30 days** of attendance data
- **Weekdays only** (skips weekends)
- **Realistic check-in/check-out times**
- **Geographic coordinates** (Singapore area)

### Performance Levels

#### GOOD Priority (92-96% attendance)
- **Emma Consistent**: 96% attendance, always on time (7:00-7:05 AM)
- **James Punctual**: 95% attendance, always on time (7:00-7:08 AM)
- **Maria Dedicated**: 94% attendance, rarely late (7:00-7:10 AM, 2% chance of 7:15-7:30 AM)
- **Alex Steady**: 93% attendance, mostly on time (7:00-7:12 AM, 3% chance of 7:20-7:45 AM)
- **Sophia Reliable**: 92% attendance, good performance (7:00-7:15 AM, 4% chance of 7:30-8:00 AM)

#### MEDIUM Priority (80-89% attendance)
- **Ryan Variable**: 89% attendance, occasional late arrivals (20% chance of 8:00-8:30 AM)
- **Olivia Irregular**: 87% attendance, some late arrivals (25% chance of 8:00-9:00 AM)
- **Noah Inconsistent**: 85% attendance, frequent late arrivals (30% chance of 8:00-9:30 AM)
- **Ava Moderate**: 83% attendance, moderate late arrivals (25% chance of 8:00-9:15 AM)
- **Liam Average**: 80% attendance, many late arrivals (30% chance of 8:00-9:45 AM)

## Priority Logic

The script creates data that matches the dashboard's priority calculation logic:
- **GOOD**: ≥90% attendance, no or very few issues
- **MEDIUM**: 80-89% attendance, some late arrivals or minor issues
- **HIGH**: <80% attendance, many late arrivals, frequent absences

## Verification

After running the script, you can verify the data by checking the dashboard's Performance Overview section. The new workers should appear in the appropriate priority categories:

- **GOOD section**: Should show Emma, James, Maria, Alex, and Sophia
- **MEDIUM section**: Should show Ryan, Olivia, Noah, Ava, and Liam

## Notes

- All workers use the password: `worker123`
- The script uses `ON CONFLICT DO NOTHING` to avoid errors if workers already exist
- Existing attendance records for these workers are cleared before creating new ones
- The script generates realistic attendance patterns with variations

## Combined with Original Seed

If you've already run `seed_attendance_priority.sql`, this script adds more variety:
- **Original**: 3 GOOD + 3 MEDIUM + 3 HIGH = 9 workers
- **Additional**: 5 GOOD + 5 MEDIUM = 10 workers
- **Total**: 8 GOOD + 8 MEDIUM + 3 HIGH = 19 workers

This provides a more comprehensive dataset for testing and demonstration purposes.

