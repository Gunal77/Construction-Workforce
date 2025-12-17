const { getClient } = require('../config/db');

async function populateStaffsAndAssignToClients() {
  const client = await getClient();
  
  try {
    await client.query('BEGIN');
    
    console.log('🔄 Starting to populate staffs table and assign to clients...');
    
    // Step 1: Copy employees to staffs table (if not already exists)
    console.log('📋 Step 1: Copying employees to staffs table...');
    const copyQuery = `
      INSERT INTO staffs (id, name, email, phone, role, project_id, created_at, updated_at)
      SELECT 
        id,
        name,
        email,
        phone,
        role,
        project_id,
        created_at,
        NOW() as updated_at
      FROM employees
      WHERE NOT EXISTS (SELECT 1 FROM staffs WHERE staffs.id = employees.id)
      ON CONFLICT (id) DO NOTHING
    `;
    
    const copyResult = await client.query(copyQuery);
    console.log(`✅ Copied ${copyResult.rowCount} employees to staffs table`);
    
    // Step 2: Update staffs with client_user_id based on their project
    console.log('🔗 Step 2: Linking staffs to clients via projects...');
    const linkStaffsQuery = `
      UPDATE staffs s
      SET client_user_id = p.client_user_id,
          updated_at = NOW()
      FROM projects p
      WHERE s.project_id = p.id
        AND p.client_user_id IS NOT NULL
        AND s.client_user_id IS NULL
    `;
    
    const linkResult = await client.query(linkStaffsQuery);
    console.log(`✅ Linked ${linkResult.rowCount} staffs to clients`);
    
    // Step 3: Get all clients
    console.log('👥 Step 3: Getting all clients...');
    const clientsResult = await client.query(`
      SELECT id, name, email FROM users WHERE role = 'client' ORDER BY created_at
    `);
    const clients = clientsResult.rows;
    console.log(`📊 Found ${clients.length} clients`);
    
    // Step 4: For each client, ensure they have at least one project
    console.log('🏗️  Step 4: Assigning projects to clients...');
    for (const clientData of clients) {
      // Check if client has projects
      const projectCheck = await client.query(
        'SELECT COUNT(*) as count FROM projects WHERE client_user_id = $1',
        [clientData.id]
      );
      
      const projectCount = parseInt(projectCheck.rows[0].count);
      
      if (projectCount === 0) {
        // Create a default project for this client
        const projectResult = await client.query(`
          INSERT INTO projects (name, location, description, client_user_id, start_date, created_at)
          VALUES ($1, $2, $3, $4, CURRENT_DATE, NOW())
          RETURNING id
        `, [
          `${clientData.name}'s Project`,
          'Singapore',
          `Default project for ${clientData.name}`,
          clientData.id
        ]);
        
        console.log(`  ✅ Created project for ${clientData.name}`);
        
        // Get some employees to assign to this project
        const employeesResult = await client.query(`
          SELECT id FROM employees 
          WHERE project_id IS NULL 
          LIMIT 3
        `);
        
        if (employeesResult.rows.length > 0) {
          const projectId = projectResult.rows[0].id;
          
          // Assign employees to project
          for (const emp of employeesResult.rows) {
            await client.query(
              'UPDATE employees SET project_id = $1 WHERE id = $2',
              [projectId, emp.id]
            );
            
            // Also add to staffs if not exists
            await client.query(`
              INSERT INTO staffs (id, name, email, phone, role, project_id, client_user_id, created_at, updated_at)
              SELECT id, name, email, phone, role, $1, $2, created_at, NOW()
              FROM employees
              WHERE id = $3
              ON CONFLICT (id) DO UPDATE 
              SET project_id = $1, client_user_id = $2, updated_at = NOW()
            `, [projectId, clientData.id, emp.id]);
          }
          
          console.log(`  ✅ Assigned ${employeesResult.rows.length} staff to ${clientData.name}'s project`);
        }
        
        // Assign a supervisor to this project if available
        const supervisorsResult = await client.query(`
          SELECT id FROM supervisors 
          WHERE id NOT IN (
            SELECT DISTINCT supervisor_id FROM supervisor_projects_relation
          )
          LIMIT 1
        `);
        
        if (supervisorsResult.rows.length > 0) {
          const supervisorId = supervisorsResult.rows[0].id;
          await client.query(`
            INSERT INTO supervisor_projects_relation (supervisor_id, project_id, assigned_at)
            VALUES ($1, $2, NOW())
            ON CONFLICT (supervisor_id, project_id) DO NOTHING
          `, [supervisorId, projectId]);
          
          console.log(`  ✅ Assigned supervisor to ${clientData.name}'s project`);
        }
      } else {
        // Client already has projects, just ensure staffs are linked
        const updateStaffsQuery = `
          UPDATE staffs s
          SET client_user_id = p.client_user_id,
              updated_at = NOW()
          FROM projects p
          WHERE s.project_id = p.id
            AND p.client_user_id = $1
            AND s.client_user_id IS NULL
        `;
        
        await client.query(updateStaffsQuery, [clientData.id]);
        console.log(`  ℹ️  ${clientData.name} already has ${projectCount} project(s)`);
      }
    }
    
    // Step 5: Summary
    console.log('\n📊 Summary:');
    const summaryQuery = `
      SELECT 
        (SELECT COUNT(*) FROM projects WHERE client_user_id IS NOT NULL) as total_projects_with_clients,
        (SELECT COUNT(DISTINCT client_user_id) FROM projects WHERE client_user_id IS NOT NULL) as clients_with_projects,
        (SELECT COUNT(*) FROM staffs) as total_staffs,
        (SELECT COUNT(*) FROM staffs WHERE client_user_id IS NOT NULL) as staffs_with_clients,
        (SELECT COUNT(*) FROM supervisor_projects_relation) as supervisor_assignments
    `;
    
    const summary = await client.query(summaryQuery);
    const stats = summary.rows[0];
    
    console.log(`  • Projects with clients: ${stats.total_projects_with_clients}`);
    console.log(`  • Clients with projects: ${stats.clients_with_projects}`);
    console.log(`  • Total staffs: ${stats.total_staffs}`);
    console.log(`  • Staffs linked to clients: ${stats.staffs_with_clients}`);
    console.log(`  • Supervisor assignments: ${stats.supervisor_assignments}`);
    
    await client.query('COMMIT');
    console.log('\n✅ Successfully populated staffs table and assigned to clients!');
    
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('❌ Error:', error);
    throw error;
  } finally {
    client.release();
  }
}

// Run the script
populateStaffsAndAssignToClients()
  .then(() => {
    console.log('✨ Script completed successfully!');
    process.exit(0);
  })
  .catch((error) => {
    console.error('💥 Script failed:', error);
    process.exit(1);
  });

