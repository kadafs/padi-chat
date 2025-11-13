# Phase 1: Manual Testing Guide (No Docker)

This guide will walk you through manually testing Phase 1 without Docker.

## Prerequisites Check

✅ Ruby installed: `ruby 3.4.7`
✅ Bundler installed: `Bundler version 2.6.9`
⚠️ PostgreSQL: Need to verify connection

## Step 1: Install Dependencies

If gems aren't installed yet:

```bash
bundle install
```

This may take a few minutes as it installs all required gems.

## Step 2: Verify Database Connection

Make sure PostgreSQL is running and accessible. Check your database configuration in `config/database.yml`:

- Database: `chaskiq_dev` (default)
- Username: `postgres` (default)
- Password: (empty by default, or set via `POSTGRES_PASSWORD` env var)
- Host: `localhost` (default)

You can test the connection by running:

```bash
bundle exec rails db:version
```

If this fails, you may need to:
1. Start PostgreSQL service
2. Create the database: `bundle exec rails db:create`
3. Check your database credentials

## Step 3: Run the Migration

Once the database connection works, run the migration:

```bash
bundle exec rails db:migrate
```

This will create all the Tidio enhancement tables. You should see output like:

```
== 20241112000001 CreateTidioEnhancements: migrating ========================
-- create_table(:visitor_sessions)
   -> 0.0123s
-- create_table(:chat_ratings)
   -> 0.0089s
...
== 20241112000001 CreateTidioEnhancements: migrated (0.1234s) ===============
```

## Step 4: Run Validation Script

Run our comprehensive validation:

```bash
bundle exec rails tidio:validate
```

This will check:
- ✅ All tables exist
- ✅ Model associations work
- ✅ Service objects exist
- ✅ GraphQL types exist
- ✅ GraphQL mutations exist
- ✅ Basic CRUD operations work

## Step 5: Test GraphQL Schema

Test that GraphQL queries and mutations are registered:

```bash
bundle exec rails tidio:test_graphql
```

## Step 6: Manual Testing in Rails Console

Open Rails console:

```bash
bundle exec rails console
```

### Test 1: Check Models Load

```ruby
# Check that models are loaded
VisitorSession
ProactiveMessage
FlowBuilder
ChatRating
EmailSequence
ConversationAnalytics
TypingIndicator
SharedFile
ContactList
WidgetTheme
PushNotification
WebhookEvent

# Should return the class, not an error
```

### Test 2: Test App Associations

```ruby
# Get an app (or create one if none exists)
app = App.first

# If no apps exist, you'll need to create one first
# app = App.create!(name: "Test App", key: "test-app-#{SecureRandom.hex(4)}")

# Test associations
app.visitor_sessions
app.proactive_messages
app.flow_builders
app.email_sequences
app.contact_lists
app.widget_themes
app.push_notifications
app.webhook_events

# Should return empty ActiveRecord::Relation, not errors
```

### Test 3: Create Test Data

```ruby
app = App.first
return puts "No app found. Create an app first." unless app

# Create a test app user
app_user = app.app_users.first || app.app_users.create!(
  email: 'test@example.com',
  session_id: SecureRandom.hex(16)
)

# Test VisitorSession creation
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

puts "✓ VisitorSession created: #{session.id}"
puts "  Session ID: #{session.session_id}"
puts "  Current Page: #{session.current_page}"

# Test ProactiveMessage creation
message = app.proactive_messages.create!(
  name: 'Test Campaign',
  trigger_type: 'time_based',
  delay_seconds: 30,
  active: true,
  message_content: { text: 'Test message' },
  trigger_conditions: {},
  targeting_rules: {}
)

puts "✓ ProactiveMessage created: #{message.id}"
puts "  Name: #{message.name}"
puts "  Active: #{message.active}"

# Test FlowBuilder creation
flow = app.flow_builders.create!(
  name: 'Test Flow',
  active: true,
  flow_data: { nodes: [], connections: [] },
  triggers: {}
)

puts "✓ FlowBuilder created: #{flow.id}"
puts "  Name: #{flow.name}"
puts "  Active: #{flow.active}"

# Test associations
puts "\nAssociation counts:"
puts "  Visitor Sessions: #{app.visitor_sessions.count}"
puts "  Proactive Messages: #{app.proactive_messages.count}"
puts "  Flow Builders: #{app.flow_builders.count}"
```

### Test 4: Test Service Objects

```ruby
app = App.first
return puts "No app found" unless app

# Test VisitorTrackingService
service = VisitorTrackingService.new(app)
puts "✓ VisitorTrackingService instantiated"

# Test ProactiveMessageService
pm_service = ProactiveMessageService.new(app)
puts "✓ ProactiveMessageService instantiated"

# Test a service method (if you have a visitor session)
session = app.visitor_sessions.first
if session
  analytics = service.get_analytics('7d')
  puts "✓ VisitorTrackingService.get_analytics works"
  puts "  Analytics keys: #{analytics.keys.join(', ')}"
end
```

### Test 5: Test GraphQL Types

```ruby
# Check if GraphQL types are loaded
Types::VisitorSessionType
Types::ProactiveMessageType
Types::FlowBuilderType
Types::ChatRatingType
Types::EmailSequenceType
Types::ConversationAnalyticsType

# Should return the type class, not errors
puts "✓ All GraphQL types loaded"
```

### Test 6: Test GraphQL Schema

```ruby
# Load the schema
schema = ChaskiqSchema

# Check Query type
query_type = schema.types['Query']
puts "✓ Query type found"

# Check for our queries
visitor_query = query_type.fields['visitorSessions']
proactive_query = query_type.fields['proactiveMessages']
flows_query = query_type.fields['flows']

puts "✓ visitorSessions query: #{visitor_query ? 'found' : 'NOT found'}"
puts "✓ proactiveMessages query: #{proactive_query ? 'found' : 'NOT found'}"
puts "✓ flows query: #{flows_query ? 'found' : 'NOT found'}"

# Check Mutation type
mutation_type = schema.types['Mutation']
puts "✓ Mutation type found"

# Check for our mutations
track_visitor = mutation_type.fields['trackVisitor']
create_campaign = mutation_type.fields['createProactiveCampaign']
create_flow = mutation_type.fields['createFlow']

puts "✓ trackVisitor mutation: #{track_visitor ? 'found' : 'NOT found'}"
puts "✓ createProactiveCampaign mutation: #{create_campaign ? 'found' : 'NOT found'}"
puts "✓ createFlow mutation: #{create_flow ? 'found' : 'NOT found'}"
```

## Step 7: Test GraphQL Queries (Optional)

If you have GraphiQL or a GraphQL client available, you can test queries directly.

### Start Rails Server

```bash
bundle exec rails server
```

Then navigate to `/graphiql` (if enabled) or use a GraphQL client.

### Example Query: Get Visitor Sessions

```graphql
query {
  visitorSessions(appKey: "your-app-key") {
    id
    sessionId
    currentPage
    deviceType
    isOnline
    locationString
    durationFormatted
  }
}
```

### Example Mutation: Track Visitor

```graphql
mutation {
  trackVisitor(
    appKey: "your-app-key"
    visitorData: {
      sessionId: "test_session_123"
      currentPage: "/test"
      deviceType: "desktop"
      browser: "Chrome"
      os: "Windows"
      countryCode: "US"
      city: "Test City"
    }
  ) {
    visitorSession {
      id
      sessionId
      isOnline
    }
    errors
  }
}
```

## Troubleshooting

### "bundler: command not found: rails"

Run: `bundle install` to install all gems including Rails.

### Database Connection Error

1. Check PostgreSQL is running
2. Verify credentials in `config/database.yml`
3. Create database: `bundle exec rails db:create`
4. Check environment variables: `POSTGRES_DATABASE`, `POSTGRES_USERNAME`, `POSTGRES_PASSWORD`

### Migration Fails

1. Check if tables already exist: `bundle exec rails db:migrate:status`
2. If migration partially ran, you may need to rollback: `bundle exec rails db:rollback`
3. Check migration file for syntax errors

### Model Not Found Errors

1. Restart Rails console
2. Check that model files exist in `app/models/`
3. Verify model class names match file names

### GraphQL Queries Not Found

1. Restart Rails server
2. Check `app/graphql/types/query_type.rb` includes query extensions
3. Check `app/graphql/types/mutation_type.rb` includes mutations
4. Verify GraphQL schema loads: `bundle exec rails tidio:test_graphql`

## Success Criteria

Phase 1 is complete when:

- ✅ Migration runs without errors
- ✅ All 15 tables are created
- ✅ Validation script passes all checks
- ✅ Models can be created in Rails console
- ✅ Associations work correctly
- ✅ GraphQL queries are registered
- ✅ GraphQL mutations are registered
- ✅ Service objects can be instantiated

## Next Steps

Once Phase 1 validation passes:

1. **Phase 2**: Connect frontend to backend (replace mock data with real GraphQL queries)
2. **Phase 3**: Implement real-time features (ActionCable subscriptions)
3. **Phase 4**: Build missing UI components (campaign manager, email sequences, etc.)

