const { Pool } = require('pg');
const env = require('./env');

// Validate database URL format
if (!env.databaseUrl) {
  throw new Error('DATABASE_URL is not set in environment variables');
}

// Check if it's a Supabase connection
const isSupabase = env.databaseUrl.includes('supabase.co') || env.databaseUrl.includes('supabase.com');

const pool = new Pool({
  connectionString: env.databaseUrl,
  ssl: isSupabase
    ? { rejectUnauthorized: false }
    : undefined,
  // Connection timeout settings
  connectionTimeoutMillis: 10000,
  idleTimeoutMillis: 30000,
  max: 20,
});

pool.on('error', (err) => {
  console.error('Unexpected database error', err);
  if (err.code === 'ENOTFOUND') {
    console.error('\n❌ Database hostname not found. Possible issues:');
    console.error('   1. Supabase project might be paused or deleted');
    console.error('   2. Check your DATABASE_URL in .env file');
    console.error('   3. Verify your Supabase project is active');
    console.error('   4. Try using connection pooling URL instead of direct connection');
    console.error('\n   Get connection string from: Supabase Dashboard > Settings > Database > Connection string');
  }
});

const initializeDatabase = async () => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    await client.query(`
      CREATE TABLE IF NOT EXISTS users (
        id UUID PRIMARY KEY,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        created_at TIMESTAMPTZ DEFAULT NOW()
      )
    `);

    await client.query(`
      CREATE TABLE IF NOT EXISTS attendance_logs (
        id UUID PRIMARY KEY,
        user_id UUID REFERENCES users(id) ON DELETE CASCADE,
        check_in_time TIMESTAMPTZ NOT NULL,
        check_out_time TIMESTAMPTZ,
        image_url TEXT,
        latitude DOUBLE PRECISION,
        longitude DOUBLE PRECISION,
        created_at TIMESTAMPTZ DEFAULT NOW()
      )
    `);

    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_attendance_logs_user_id
      ON attendance_logs (user_id)
    `);

    await client.query('COMMIT');
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Failed to initialize database', error);
    throw error;
  } finally {
    client.release();
  }
};

module.exports = {
  pool,
  query: (text, params) => pool.query(text, params),
  getClient: () => pool.connect(),
  initializeDatabase,
};

