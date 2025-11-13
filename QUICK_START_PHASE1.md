# Quick Start: Phase 1 Manual Testing

## Current Status
- ✅ Ruby 3.4.7 installed (Gemfile requires 3.3.5 - may still work)
- ✅ Bundler 2.6.9 installed
- ⚠️ Need to install gems
- ⚠️ Need PostgreSQL running

## Step-by-Step Instructions

### Step 1: Install Gems (May have Ruby version warning)

```bash
bundle install
```

**Note**: If you get a Ruby version warning, you can either:
- Ignore it and continue (Ruby 3.4.7 should be compatible)
- Or update Gemfile to allow 3.4.7: Change `ruby "3.3.5"` to `ruby ">= 3.3.5"`

### Step 2: Check Database Connection

Make sure PostgreSQL is running. Then test connection:

```bash
bundle exec rails db:version
```

**If this fails:**
1. Start PostgreSQL service (Windows: Services → PostgreSQL)
2. Or create database: `bundle exec rails db:create`
3. Check your database credentials in `config/database.yml`

### Step 3: Run Migration

```bash
bundle exec rails db:migrate
```

**Expected output:**
```
== 20241112000001 CreateTidioEnhancements: migrating ========================
-- create_table(:visitor_sessions)
   -> 0.0123s
...
== 20241112000001 CreateTidioEnhancements: migrated (0.1234s) ===============
```

### Step 4: Run Validation

```bash
bundle exec rails tidio:validate
```

This comprehensive check will verify everything is set up correctly.

### Step 5: Test GraphQL Schema

```bash
bundle exec rails tidio:test_graphql
```

### Step 6: Quick Console Test

Open Rails console:

```bash
bundle exec rails console
```

Then run these quick tests:

```ruby
# 1. Check models load
VisitorSession
ProactiveMessage
FlowBuilder

# 2. Get an app
app = App.first

# 3. Test associations (should return empty relations, not errors)
app.visitor_sessions
app.proactive_messages
app.flow_builders

# 4. Create a test visitor session
app_user = app.app_users.first || app.app_users.create!(
  email: 'test@example.com',
  session_id: SecureRandom.hex(16)
)

session = app.visitor_sessions.create!(
  app_user: app_user,
  session_id: SecureRandom.hex(16),
  current_page: '/test',
  device_type: 'desktop',
  browser: 'Chrome',
  os: 'Windows',
  country_code: 'US',
  city: 'Test City',
  page_views: 1,
  time_on_site: 0
)

puts "✓ Created VisitorSession: #{session.id}"

# 5. Test GraphQL schema
schema = ChaskiqSchema
query_type = schema.types['Query']
puts "✓ visitorSessions query: #{query_type.fields['visitorSessions'] ? 'found' : 'NOT found'}"
```

## Troubleshooting

### "bundler: command not found: rails"
- Run `bundle install` first
- If still fails, try `bundle exec rails` instead of just `rails`

### Database Connection Error
- Check PostgreSQL is running
- Verify database exists: `bundle exec rails db:create`
- Check `config/database.yml` for correct credentials

### Ruby Version Warning
- You can ignore it if bundle install succeeds
- Or update Gemfile: change `ruby "3.3.5"` to `ruby ">= 3.3.5"`

### Migration Errors
- Check if migration already ran: `bundle exec rails db:migrate:status`
- If partially run, rollback: `bundle exec rails db:rollback STEP=1`
- Then run again: `bundle exec rails db:migrate`

## Success Indicators

✅ Migration completes without errors
✅ Validation script shows all checks passing
✅ GraphQL test shows queries/mutations registered
✅ Can create models in Rails console
✅ No errors when testing associations

## Next Steps After Phase 1

Once validation passes:
1. Phase 2: Connect frontend to backend
2. Phase 3: Real-time features
3. Phase 4: Missing UI components

