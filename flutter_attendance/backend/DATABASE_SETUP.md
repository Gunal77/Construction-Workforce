# Database Connection Setup

## Issue: ENOTFOUND Error

If you're getting `ENOTFOUND db.xxxxx.supabase.co` error, follow these steps:

## Solution 1: Verify Supabase Project Status

1. Go to [Supabase Dashboard](https://app.supabase.com)
2. Check if your project is **Active** (not paused)
3. If paused, click "Restore" to reactivate

## Solution 2: Get Correct Connection String

### Option A: Direct Connection (Transaction Mode)
1. Go to Supabase Dashboard > Your Project
2. Navigate to **Settings** > **Database**
3. Under **Connection string**, select **URI**
4. Copy the connection string (starts with `postgresql://`)
5. Update your `.env` file:

```env
DATABASE_URL=postgresql://postgres:[YOUR-PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres
```

### Option B: Connection Pooling (Recommended for Production)
1. Go to Supabase Dashboard > Your Project
2. Navigate to **Settings** > **Database**
3. Under **Connection string**, select **Connection pooling** > **Transaction mode**
4. Copy the connection string (uses port 6543)
5. Update your `.env` file:

```env
DATABASE_URL=postgresql://postgres.[PROJECT-REF]:[YOUR-PASSWORD]@aws-0-[REGION].pooler.supabase.com:6543/postgres
```

## Solution 3: Update .env File

Edit `flutter_attendance/backend/.env`:

```env
# Database Connection
# Use connection pooling URL for better performance
DATABASE_URL=postgresql://postgres.[PROJECT-REF]:[PASSWORD]@aws-0-[REGION].pooler.supabase.com:6543/postgres

# Or use direct connection
# DATABASE_URL=postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres

# Supabase Configuration
SUPABASE_URL=https://[PROJECT-REF].supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
SUPABASE_BUCKET=attendance

# JWT Secret
JWT_SECRET=your-jwt-secret-key

# Server Port
PORT=4000
```

## Solution 4: Test Connection

Test your database connection:

```bash
# Install psql if not available
# Then test connection:
psql "postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres"
```

## Common Issues

### Project Paused
- Free tier projects pause after 1 week of inactivity
- Reactivate from Supabase Dashboard

### Wrong Password
- Reset password in Supabase Dashboard > Settings > Database
- Update `.env` with new password

### Network/Firewall
- Ensure your IP is allowed (if IP restrictions are enabled)
- Check firewall settings

### Connection String Format
- Ensure password is URL-encoded if it contains special characters
- Use `%40` for `@`, `%3A` for `:`, etc.

## Verify Connection

After updating `.env`, restart the server:

```bash
npm run dev
```

You should see:
```
Server listening on port 4000
```

If errors persist, check:
1. Supabase project status
2. Connection string format
3. Network connectivity
4. Environment variables are loaded correctly

