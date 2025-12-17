const { pool } = require('../config/db');

async function testClientCounts() {
  try {
    console.log('🧪 Testing client counts query...\n');
    
    // Test the exact query from the route
    const query = `
      SELECT 
        u.id,
        u.name,
        u.email,
        u.phone,
        COALESCE(u.is_active, TRUE) as is_active,
        u.created_at,
        (SELECT COUNT(*) FROM projects WHERE client_user_id = u.id) as project_count,
        (SELECT COUNT(DISTINCT s.id) 
         FROM supervisors s
         INNER JOIN supervisor_projects_relation spr ON spr.supervisor_id = s.id
         INNER JOIN projects p ON p.id = spr.project_id
         WHERE p.client_user_id = u.id) as supervisor_count,
        (SELECT COUNT(DISTINCT COALESCE(s.id, e.id))
         FROM projects p
         LEFT JOIN staffs s ON s.project_id = p.id
         LEFT JOIN employees e ON e.project_id = p.id
         WHERE p.client_user_id = u.id
           AND (s.id IS NOT NULL OR e.id IS NOT NULL)) as staff_count
      FROM users u
      WHERE u.role = 'client'
      ORDER BY u.created_at DESC
      LIMIT 5
    `;
    
    const result = await pool.query(query);
    
    console.log('📊 Results:');
    console.log('='.repeat(80));
    result.rows.forEach((row, index) => {
      console.log(`\n${index + 1}. ${row.name} (${row.email})`);
      console.log(`   Projects: ${row.project_count}`);
      console.log(`   Supervisors: ${row.supervisor_count}`);
      console.log(`   Staff: ${row.staff_count}`);
    });
    
    console.log('\n' + '='.repeat(80));
    
    // Also check raw data
    console.log('\n🔍 Verifying raw data...\n');
    
    const clientsCheck = await pool.query(`
      SELECT id, name FROM users WHERE role = 'client' LIMIT 3
    `);
    
    for (const client of clientsCheck.rows) {
      console.log(`\nClient: ${client.name} (${client.id})`);
      
      const projects = await pool.query(
        'SELECT COUNT(*) as count FROM projects WHERE client_user_id = $1',
        [client.id]
      );
      console.log(`  Projects: ${projects.rows[0].count}`);
      
      const supervisors = await pool.query(`
        SELECT COUNT(DISTINCT s.id) as count
        FROM supervisors s
        INNER JOIN supervisor_projects_relation spr ON spr.supervisor_id = s.id
        INNER JOIN projects p ON p.id = spr.project_id
        WHERE p.client_user_id = $1
      `, [client.id]);
      console.log(`  Supervisors: ${supervisors.rows[0].count}`);
      
      const staff = await pool.query(`
        SELECT COUNT(DISTINCT COALESCE(s.id, e.id)) as count
        FROM projects p
        LEFT JOIN staffs s ON s.project_id = p.id
        LEFT JOIN employees e ON e.project_id = p.id
        WHERE p.client_user_id = $1
          AND (s.id IS NOT NULL OR e.id IS NOT NULL)
      `, [client.id]);
      console.log(`  Staff: ${staff.rows[0].count}`);
    }
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

testClientCounts();

