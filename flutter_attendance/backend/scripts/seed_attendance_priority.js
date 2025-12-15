/**
 * Seed Attendance Priority Sample Data
 * 
 * Creates sample workers and attendance records to demonstrate
 * GOOD, MEDIUM, and HIGH priority performance levels
 * 
 * Usage: node scripts/seed_attendance_priority.js
 */

const db = require('../config/db');
const bcrypt = require('bcrypt');
const crypto = require('crypto');

// Sample workers with different performance levels
const sampleWorkers = [
  // GOOD Priority Workers (90%+ attendance, no issues)
  { name: 'John Excellent', email: 'john.excellent@example.com', role: 'Carpenter', priority: 'GOOD' },
  { name: 'Sarah Perfect', email: 'sarah.perfect@example.com', role: 'Electrician', priority: 'GOOD' },
  { name: 'Mike Reliable', email: 'mike.reliable@example.com', role: 'Plumber', priority: 'GOOD' },
  
  // MEDIUM Priority Workers (85-89% attendance, some late arrivals)
  { name: 'David Average', email: 'david.average@example.com', role: 'Mason', priority: 'MEDIUM' },
  { name: 'Lisa Moderate', email: 'lisa.moderate@example.com', role: 'Painter', priority: 'MEDIUM' },
  { name: 'Tom Occasional', email: 'tom.occasional@example.com', role: 'Welder', priority: 'MEDIUM' },
  
  // HIGH Priority Workers (<80% attendance, absences, late arrivals)
  { name: 'Robert Problem', email: 'robert.problem@example.com', role: 'Laborer', priority: 'HIGH' },
  { name: 'Jane Absent', email: 'jane.absent@example.com', role: 'Carpenter', priority: 'HIGH' },
  { name: 'Chris Late', email: 'chris.late@example.com', role: 'Electrician', priority: 'HIGH' },
];

async function seedAttendancePriority() {
  const client = await db.getClient();
  
  try {
    await client.query('BEGIN');
    console.log('🌱 Seeding attendance priority sample data...\n');

    const today = new Date();
    const thirtyDaysAgo = new Date(today);
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    let workersCreated = 0;
    let usersCreated = 0;
    let attendanceRecordsCreated = 0;

    for (const workerData of sampleWorkers) {
      console.log(`\n📋 Processing: ${workerData.name} (${workerData.priority} priority)`);

      // 1. Create or get employee
      let employeeId;
      const employeeCheck = await client.query(
        'SELECT id FROM employees WHERE email = $1',
        [workerData.email]
      );

      if (employeeCheck.rows.length > 0) {
        employeeId = employeeCheck.rows[0].id;
        console.log(`   ✓ Employee already exists: ${employeeId}`);
      } else {
        const employeeResult = await client.query(
          `INSERT INTO employees (id, name, email, role, created_at)
           VALUES ($1, $2, $3, $4, NOW())
           RETURNING id`,
          [crypto.randomUUID(), workerData.name, workerData.email, workerData.role]
        );
        employeeId = employeeResult.rows[0].id;
        workersCreated++;
        console.log(`   ✓ Created employee: ${employeeId}`);
      }

      // 2. Create or get user (for attendance_logs)
      let userId;
      const userCheck = await client.query(
        'SELECT id FROM users WHERE email = $1',
        [workerData.email]
      );

      if (userCheck.rows.length > 0) {
        userId = userCheck.rows[0].id;
        console.log(`   ✓ User already exists: ${userId}`);
      } else {
        const passwordHash = await bcrypt.hash('worker123', 12);
        const userResult = await client.query(
          `INSERT INTO users (id, email, password_hash, created_at)
           VALUES ($1, $2, $3, NOW())
           RETURNING id`,
          [crypto.randomUUID(), workerData.email, passwordHash]
        );
        userId = userResult.rows[0].id;
        usersCreated++;
        console.log(`   ✓ Created user: ${userId}`);
      }

      // 3. Delete existing attendance records for this user (to start fresh)
      await client.query(
        'DELETE FROM attendance_logs WHERE user_id = $1',
        [userId]
      );
      console.log(`   ✓ Cleared existing attendance records`);

      // 4. Create attendance records based on priority
      let recordsCreated = 0;
      const expectedCheckInHour = 7;
      const expectedCheckInMinute = 0;

      for (let day = 0; day < 30; day++) {
        const date = new Date(today);
        date.setDate(date.getDate() - day);
        const dayOfWeek = date.getDay();

        // Skip weekends (Saturday = 6, Sunday = 0)
        if (dayOfWeek === 0 || dayOfWeek === 6) continue;

        let shouldCreateRecord = true;
        let checkInHour = expectedCheckInHour;
        let checkInMinute = expectedCheckInMinute;
        let checkOutHour = 17; // 5 PM
        let checkOutMinute = 0;

        // Determine attendance pattern based on priority
        if (workerData.priority === 'GOOD') {
          // GOOD: 95% attendance, always on time (7:00 AM sharp)
          if (Math.random() < 0.05) {
            // 5% chance of absence
            shouldCreateRecord = false;
          } else {
            // Always on time, slight variation (7:00 - 7:05 AM)
            checkInMinute = Math.floor(Math.random() * 6);
          }
        } else if (workerData.priority === 'MEDIUM') {
          // MEDIUM: 87% attendance, some late arrivals
          if (Math.random() < 0.13) {
            // 13% chance of absence
            shouldCreateRecord = false;
          } else if (Math.random() < 0.25) {
            // 25% chance of being late (8:00 - 9:00 AM)
            checkInHour = 8 + Math.floor(Math.random() * 2);
            checkInMinute = Math.floor(Math.random() * 60);
          } else {
            // On time with slight variation
            checkInMinute = Math.floor(Math.random() * 15);
          }
        } else if (workerData.priority === 'HIGH') {
          // HIGH: 70% attendance, many late arrivals, absences
          if (Math.random() < 0.30) {
            // 30% chance of absence
            shouldCreateRecord = false;
          } else if (Math.random() < 0.50) {
            // 50% chance of being late (8:00 AM - 10:00 AM)
            checkInHour = 8 + Math.floor(Math.random() * 3);
            checkInMinute = Math.floor(Math.random() * 60);
          } else {
            // Sometimes on time
            checkInMinute = Math.floor(Math.random() * 30);
          }
        }

        if (shouldCreateRecord) {
          const checkInTime = new Date(date);
          checkInTime.setHours(checkInHour, checkInMinute, 0, 0);

          // Check-out time: 4-6 hours after check-in
          const workHours = 4 + Math.floor(Math.random() * 3);
          const checkOutTime = new Date(checkInTime);
          checkOutTime.setHours(checkInHour + workHours, checkOutMinute, 0, 0);

          try {
            await client.query(
              `INSERT INTO attendance_logs (id, user_id, check_in_time, check_out_time, latitude, longitude)
               VALUES ($1, $2, $3, $4, $5, $6)`,
              [
                crypto.randomUUID(),
                userId,
                checkInTime.toISOString(),
                checkOutTime.toISOString(),
                1.3521 + (Math.random() - 0.5) * 0.01, // Singapore area coordinates
                103.8198 + (Math.random() - 0.5) * 0.01,
              ]
            );
            recordsCreated++;
          } catch (error) {
            console.log(`   ⚠️  Error creating attendance record: ${error.message}`);
          }
        }
      }

      console.log(`   ✅ Created ${recordsCreated} attendance records`);
      attendanceRecordsCreated += recordsCreated;
    }

    await client.query('COMMIT');
    console.log('\n✅ Successfully seeded attendance priority data!');
    console.log(`\n📊 Summary:`);
    console.log(`   - Workers created: ${workersCreated}`);
    console.log(`   - Users created: ${usersCreated}`);
    console.log(`   - Attendance records created: ${attendanceRecordsCreated}`);
    console.log(`\n🎯 Priority Breakdown:`);
    console.log(`   - GOOD Priority: 3 workers (95% attendance, always on time)`);
    console.log(`   - MEDIUM Priority: 3 workers (87% attendance, some late arrivals)`);
    console.log(`   - HIGH Priority: 3 workers (70% attendance, many absences/late arrivals)`);
    console.log(`\n💡 Note: Check the dashboard to see these workers sorted by priority!`);

  } catch (error) {
    await client.query('ROLLBACK');
    console.error('\n❌ Error seeding attendance priority data:', error);
    throw error;
  } finally {
    client.release();
  }
}

// Run the seed function
seedAttendancePriority()
  .then(() => {
    console.log('\n✨ Done!');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n💥 Failed:', error);
    process.exit(1);
  });

