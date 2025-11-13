# How to Start PostgreSQL on Windows

## Quick Start Options

### Option 1: Start Menu (Easiest)
1. Press `Windows Key` and type "PostgreSQL"
2. Look for "pgAdmin 4" or "PostgreSQL 18" in the results
3. Click to open pgAdmin 4
4. When pgAdmin opens, it will automatically connect to the local PostgreSQL server
5. This will start PostgreSQL if it's not already running

### Option 2: Windows Services
1. Press `Win + R`, type `services.msc` and press Enter
2. Look for a service named:
   - `postgresql-x64-18`
   - `PostgreSQL 18`
   - `postgresql-x64-XX` (where XX is version)
3. Right-click the service → **Start**
4. Wait for status to change to "Running"

### Option 3: Command Line (If Service Exists)
```powershell
# Find the service name first
Get-Service | Where-Object { $_.Name -like "*postgres*" }

# Then start it (replace SERVICE_NAME with actual name)
Start-Service -Name "SERVICE_NAME"
```

### Option 4: Initialize and Start (If Not Initialized)
If PostgreSQL data directory is not initialized:

```powershell
cd "C:\Program Files\PostgreSQL\18\bin"

# Initialize database cluster (only if not already done)
.\initdb.exe -D "C:\Program Files\PostgreSQL\18\data" -U postgres -A password -E UTF8 --locale=C

# Then start
.\pg_ctl.exe start -D "C:\Program Files\PostgreSQL\18\data"
```

## Verify PostgreSQL is Running

After starting, test the connection:

```powershell
& "C:\Program Files\PostgreSQL\18\bin\psql.exe" -U postgres -c "SELECT version();"
```

If this works, PostgreSQL is running!

## Common Issues

**Issue: "Connection refused"**
- PostgreSQL service is not running
- Use one of the options above to start it

**Issue: "Password authentication failed"**
- You may need to set a password or use Windows authentication
- Try: `psql -U postgres` (without password if configured)

**Issue: "Database does not exist"**
- Create it: `psql -U postgres -c "CREATE DATABASE chaskiq_dev;"`

## Next Steps After Starting

Once PostgreSQL is running:

1. **Create database (if needed):**
   ```powershell
   & "C:\Program Files\PostgreSQL\18\bin\psql.exe" -U postgres -c "CREATE DATABASE chaskiq_dev;"
   ```

2. **Run validation:**
   ```powershell
   $env:POSTGRES_DATABASE = "chaskiq_dev"
   ruby validate_postgres_schema.rb
   ```

3. **Or run migration:**
   ```powershell
   bundle exec rails db:migrate
   ```

