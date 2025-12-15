/**
 * Run SQL Seed Script
 * 
 * Reads and executes the seed_attendance_priority.sql file
 * 
 * Usage: node scripts/run_sql_seed.js
 */

const db = require('../config/db');
const fs = require('fs');
const path = require('path');

async function runSqlSeed() {
  const client = await db.getClient();
  
  try {
    console.log('📖 Reading SQL seed file...');
    const sqlFile = path.join(__dirname, 'seed_attendance_priority.sql');
    const sql = fs.readFileSync(sqlFile, 'utf8');
    
    console.log('🚀 Executing SQL script...\n');
    
    // Split SQL by semicolons and execute each statement
    // Note: This is a simple approach - for complex SQL with functions, 
    // you might want to use a proper SQL parser
    const statements = sql
      .split(';')
      .map(s => s.trim())
      .filter(s => s.length > 0 && !s.startsWith('--') && !s.startsWith('/*'));
    
    for (let i = 0; i < statements.length; i++) {
      const statement = statements[i];
      if (statement.length > 10) { // Skip very short statements
        try {
          await client.query(statement);
          console.log(`✓ Executed statement ${i + 1}/${statements.length}`);
        } catch (error) {
          // Skip errors for statements that might fail (like CREATE EXTENSION)
          if (!error.message.includes('already exists') && 
              !error.message.includes('does not exist')) {
            console.log(`⚠️  Statement ${i + 1} warning: ${error.message}`);
          }
        }
      }
    }
    
    // Execute the DO block separately (it contains the main logic)
    console.log('\n🔄 Executing attendance records generation...');
    const doBlock = sql.match(/DO \$\$[\s\S]*?\$\$;/)?.[0];
    if (doBlock) {
      await client.query(doBlock);
      console.log('✓ Attendance records generated');
    }
    
    // Execute the final SELECT to show results
    console.log('\n📊 Verifying data...');
    const verifyQuery = `
      SELECT 
        e.name,
        e.email,
        e.role,
        COUNT(al.id) as attendance_count,
        COUNT(CASE WHEN DATE(al.check_in_time) = CURRENT_DATE THEN 1 END) as present_today,
        ROUND(COUNT(al.id)::NUMERIC / 22.0 * 100, 1) as attendance_percentage
      FROM employees e
      LEFT JOIN users u ON u.email = e.email
      LEFT JOIN attendance_logs al ON al.user_id = u.id AND al.check_in_time >= CURRENT_DATE - INTERVAL '30 days'
      WHERE e.email IN (
        'john.excellent@example.com',
        'sarah.perfect@example.com',
        'mike.reliable@example.com',
        'david.average@example.com',
        'lisa.moderate@example.com',
        'tom.occasional@example.com',
        'robert.problem@example.com',
        'jane.absent@example.com',
        'chris.late@example.com'
      )
      GROUP BY e.id, e.name, e.email, e.role
      ORDER BY 
        CASE 
          WHEN e.email LIKE '%.excellent@%' OR e.email LIKE '%.perfect@%' OR e.email LIKE '%.reliable@%' THEN 1
          WHEN e.email LIKE '%.average@%' OR e.email LIKE '%.moderate@%' OR e.email LIKE '%.occasional@%' THEN 2
          ELSE 3
        END,
        attendance_percentage DESC;
    `;
    
    const result = await client.query(verifyQuery);
    console.log('\n✅ Data Summary:');
    console.table(result.rows);
    
    console.log('\n✨ Done! Refresh your dashboard to see the results.');
    
  } catch (error) {
    console.error('\n❌ Error running SQL seed:', error);
    throw error;
  } finally {
    client.release();
  }
}

// Run the function
runSqlSeed()
  .then(() => {
    process.exit(0);
  })
  .catch((error) => {
    console.error('💥 Failed:', error);
    process.exit(1);
  });

