# Phase 1 Validation - Windows Setup Guide

## Current Issues

The bundle install is failing due to:
1. **Missing PostgreSQL client library** (pg gem needs libpq)
2. **Native extension compilation failures** (grpc, io-console) - Ruby 3.4.7 compatibility

## Solutions

### Option 1: Install PostgreSQL Development Libraries (Recommended)

For Windows, you need to install PostgreSQL development libraries:

1. **Install PostgreSQL** (if not already installed):
   - Download from: https://www.postgresql.org/download/windows/
   - During installation, make sure to install "Command Line Tools"

2. **Add PostgreSQL to PATH**:
   - Find your PostgreSQL installation (usually `C:\Program Files\PostgreSQL\15\bin`)
   - Add it to your system PATH
   - Or set environment variable: `set PATH=%PATH%;C:\Program Files\PostgreSQL\15\bin`

3. **Install pg gem with path**:
   ```bash
   bundle config build.pg --with-pg-config="C:\Program Files\PostgreSQL\15\bin\pg_config.exe"
   bundle install
   ```

### Option 2: Skip Problematic Gems Temporarily

If you just want to validate the code structure, you can temporarily comment out problematic gems in Gemfile:

```ruby
# Temporarily comment these if causing issues:
# gem 'grpc'  # Only needed for AnyCable gRPC
# gem 'io-console'  # May have Ruby 3.4.7 issues
```

Then run:
```bash
bundle install --without development test
```

### Option 3: Code-Only Validation (No Database Required)

We can validate the code structure without running migrations. See `VALIDATE_CODE_STRUCTURE.md`

## Quick Fix for Phase 1

If you just want to check if the migration file and code are correct:

1. **Check migration syntax**:
   ```bash
   ruby -c db/migrate/20241112000001_create_tidio_enhancements.rb
   ```

2. **Check model files exist**:
   ```bash
   dir app\models\visitor_session.rb
   dir app\models\proactive_message.rb
   dir app\models\flow_builder.rb
   ```

3. **Check GraphQL types exist**:
   ```bash
   dir app\graphql\types\visitor_session_type.rb
   dir app\graphql\types\proactive_message_type.rb
   ```

## Recommended Next Steps

1. **Install PostgreSQL** (if not installed)
2. **Set up PostgreSQL path**
3. **Run bundle install with pg config**
4. **Then proceed with migration and validation**

## Alternative: Use Docker (If Possible)

If you can get Docker Desktop running:
```bash
docker-compose up -d postgres redis
docker-compose run --rm rails bundle exec rails db:migrate
docker-compose run --rm rails bundle exec rails tidio:validate
```

This avoids all Windows native extension issues.

