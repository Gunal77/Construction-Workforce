/**
 * Script to assign all supervisors to all projects
 * 
 * This script assigns every supervisor to every project in the database.
 * 
 * Usage: node scripts/assign_all_supervisors_to_projects.js
 */

const { supabase } = require('../config/supabaseClient');

async function assignAllSupervisorsToProjects() {
  try {
    console.log('🚀 Starting supervisor-project assignment...\n');

    // Get all projects
    console.log('📋 Fetching all projects...');
    const { data: projects, error: projectsError } = await supabase
      .from('projects')
      .select('id, name');

    if (projectsError) {
      throw new Error(`Failed to fetch projects: ${projectsError.message}`);
    }

    if (!projects || projects.length === 0) {
      console.log('⚠️  No projects found in database.');
      return;
    }

    console.log(`   ✅ Found ${projects.length} project(s)`);
    projects.forEach((p, i) => {
      console.log(`      ${i + 1}. ${p.name} (${p.id})`);
    });

    // Get all supervisors
    console.log('\n👥 Fetching all supervisors...');
    const { data: supervisors, error: supervisorsError } = await supabase
      .from('supervisors')
      .select('id, name, email');

    if (supervisorsError) {
      throw new Error(`Failed to fetch supervisors: ${supervisorsError.message}`);
    }

    if (!supervisors || supervisors.length === 0) {
      console.log('⚠️  No supervisors found in database.');
      return;
    }

    console.log(`   ✅ Found ${supervisors.length} supervisor(s)`);
    supervisors.forEach((s, i) => {
      console.log(`      ${i + 1}. ${s.name} (${s.email}) - ${s.id}`);
    });

    // Check existing relations
    console.log('\n🔍 Checking existing assignments...');
    const { data: existingRelations, error: relationsError } = await supabase
      .from('supervisor_projects_relation')
      .select('supervisor_id, project_id');

    if (relationsError) {
      console.log(`   ⚠️  Could not check existing relations: ${relationsError.message}`);
    } else {
      console.log(`   ✅ Found ${existingRelations?.length || 0} existing assignment(s)`);
    }

    // Create all possible relations
    console.log('\n🔗 Creating supervisor-project assignments...');
    const relations = [];
    let newCount = 0;
    let existingCount = 0;

    for (const project of projects) {
      for (const supervisor of supervisors) {
        // Check if relation already exists
        const exists = existingRelations?.some(
          (rel) => rel.supervisor_id === supervisor.id && rel.project_id === project.id
        );

        if (exists) {
          existingCount++;
        } else {
          relations.push({
            supervisor_id: supervisor.id,
            project_id: project.id,
          });
          newCount++;
        }
      }
    }

    console.log(`   📊 Statistics:`);
    console.log(`      - New assignments to create: ${newCount}`);
    console.log(`      - Already assigned: ${existingCount}`);
    console.log(`      - Total possible: ${projects.length * supervisors.length}`);

    if (relations.length === 0) {
      console.log('\n✅ All supervisors are already assigned to all projects!');
      return;
    }

    // Insert new relations in batches
    const batchSize = 50;
    let insertedCount = 0;
    let errorCount = 0;

    for (let i = 0; i < relations.length; i += batchSize) {
      const batch = relations.slice(i, i + batchSize);
      
      const { data: inserted, error: insertError } = await supabase
        .from('supervisor_projects_relation')
        .insert(batch)
        .select();

      if (insertError) {
        console.error(`   ❌ Error inserting batch ${Math.floor(i / batchSize) + 1}: ${insertError.message}`);
        errorCount += batch.length;
      } else {
        insertedCount += inserted?.length || 0;
        console.log(`   ✅ Inserted batch ${Math.floor(i / batchSize) + 1}/${Math.ceil(relations.length / batchSize)} (${inserted?.length || 0} relations)`);
      }
    }

    // Summary
    console.log('\n📈 Assignment Summary:');
    console.log(`   ✅ Successfully assigned: ${insertedCount} relation(s)`);
    if (errorCount > 0) {
      console.log(`   ❌ Failed: ${errorCount} relation(s)`);
    }
    console.log(`   📋 Already existed: ${existingCount} relation(s)`);
    console.log(`   📊 Total assignments: ${insertedCount + existingCount} / ${projects.length * supervisors.length}`);

    console.log('\n✅ Supervisor-project assignment completed!');
  } catch (error) {
    console.error('\n❌ Error:', error.message);
    console.error(error);
    process.exit(1);
  }
}

// Run the script
if (require.main === module) {
  assignAllSupervisorsToProjects()
    .then(() => {
      console.log('\n✨ Script completed successfully!');
      process.exit(0);
    })
    .catch((error) => {
      console.error('\n💥 Script failed:', error);
      process.exit(1);
    });
}

module.exports = { assignAllSupervisorsToProjects };

