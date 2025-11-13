# PostgreSQL Setup and Database Validation Guide

## Current Status

PostgreSQL 18 is installed on your system, but the service is not running or not configured as a Windows service.

## Option 1: Start PostgreSQL Manually

1. **Find PostgreSQL installation:**
   - PostgreSQL 18 is installed at: `C:\Program Files\PostgreSQL\18`
   - Check if `pg_ctl` is available: `C:\Program Files\PostgreSQL\18\bin\pg_ctl.exe`

2. **Start PostgreSQL server:**
   ```powershell
   # Navigate to PostgreSQL bin directory
   cd "C:\Program Files\PostgreSQL\18\bin"
   
   # Start PostgreSQL (adjust data directory if different)
   .\pg_ctl.exe start -D "C:\Program Files\PostgreSQL\18\data"
   ```

3. **Or use pgAdmin:**
   - Open pgAdmin 4 (usually in Start Menu)
   - Connect to your local server
   - This will start PostgreSQL if it's not running

## Option 2: Configure as Windows Service

1. **Register PostgreSQL as a service:**
   ```powershell
   cd "C:\Program Files\PostgreSQL\18\bin"
   .\pg_ctl.exe register -N "PostgreSQL18" -D "C:\Program Files\PostgreSQL\18\data"
   ```

2. **Start the service:**
   ```powershell
   Start-Service -Name "PostgreSQL18"
   ```

## Option 3: Use Docker (If Available)

If you have Docker Desktop installed:

```powershell
docker run --name chaskiq-postgres -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=chaskiq_development -p 5432:5432 -d postgres:15
```

Then update your connection settings:
- Host: localhost
- Port: 5432
- Database: chaskiq_development
- User: postgres
- Password: postgres

## Database Connection Settings

Once PostgreSQL is running, you can validate the schema using:

```powershell
# Set connection details (if different from defaults)
$env:DB_HOST = "localhost"
$env:DB_PORT = "5432"
$env:DB_NAME = "chaskiq_development"
$env:DB_USER = "postgres"
$env:DB_PASSWORD = "your_password"

# Run validation
ruby validate_postgres_schema.rb
```

## Create Database (If Needed)

If the database doesn't exist:

```powershell
# Connect to PostgreSQL
& "C:\Program Files\PostgreSQL\18\bin\psql.exe" -U postgres

# In psql prompt:
CREATE DATABASE chaskiq_development;
\q
```

## Run Migrations

Once PostgreSQL is running and the database exists:

```powershell
# If bundle install completes:
bundle exec rails db:create
bundle exec rails db:migrate

# Or run validation directly:
ruby validate_postgres_schema.rb
```

## Quick Test Connection

Test if PostgreSQL is accessible:

```powershell
& "C:\Program Files\PostgreSQL\18\bin\psql.exe" -U postgres -l
```

This should list all databases. If it fails, PostgreSQL is not running or not accessible.

