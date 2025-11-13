# Phase 1: Database & Backend Validation Guide

This guide will help you validate that all Tidio enhancements are properly set up in the backend.

## Prerequisites

- Docker and Docker Compose installed (recommended)
- OR Ruby, PostgreSQL, and Redis installed locally
- Database access

## Step 1: Run Database Migration

### Option A: Using Docker (Recommended)

```bash
# Start the services
docker-compose up -d postgres redis

# Run migration in the rails container
docker-compose run --rm rails bundle exec rails db:migrate

# Or if you have a runner service
docker-compose run --rm runner bundle exec rails db:migrate
```

### Option B: Local Development

```bash
# Make sure dependencies are installed
bundle install

# Run the migration
bundle exec rails db:migrate
```

### Verify Migration

Check that the migration ran successfully:

```bash
# Docker
docker-compose run --rm rails bundle exec rails db:migrate:status | grep tidio

# Local
bundle exec rails db:migrate:status | grep -i tidio
```

You should see:
```
up     20241112000001  Create tidio enhancements
```

## Step 2: Run Validation Script

We've created a comprehensive validation rake task:

```bash
# Docker
docker-compose run --rm rails bundle exec rails tidio:validate

# Local
bundle exec rails tidio:validate
```

This will check:
- ✅ All required database tables exist
- ✅ Model associations are working
- ✅ Service objects exist
- ✅ GraphQL types are present
- ✅ GraphQL mutations are present
- ✅ Basic model creation works

## Step 3: Test GraphQL Schema

Test that GraphQL queries and mutations are registered:

```bash
# Docker
docker-compose run --rm rails bundle exec rails tidio:test_graphql

# Local
bundle exec rails tidio:test_graphql
```

## Step 4: Manual Testing in Rails Console

### Option A: Docker

```bash
docker-compose run --rm rails bundle exec rails console
```

### Option B: Local

```bash
bundle exec rails console
```

### Test Model Creation

```ruby
# Get an app
app = App.first

# Create a test app user if needed
app_user = app.app_users.first || app.app_users.create!(
  email: 'test@example.com',
  session_id: SecureRandom.hex(16)
)

# Test VisitorSession
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

puts "VisitorSession created: #{session.id}"

# Test ProactiveMessage
message = app.proactive_messages.create!(
  name: 'Test Campaign',
  trigger_type: 'time_based',
  delay_seconds: 30,
  active: true,
  message_content: { text: 'Test message' },
  trigger_conditions: {},
  targeting_rules: {}
)

puts "ProactiveMessage created: #{message.id}"

# Test FlowBuilder
flow = app.flow_builders.create!(
  name: 'Test Flow',
  active: true,
  flow_data: { nodes: [], connections: [] },
  triggers: {}
)

puts "FlowBuilder created: #{flow.id}"

# Test associations
puts "App has #{app.visitor_sessions.count} visitor sessions"
puts "App has #{app.proactive_messages.count} proactive messages"
puts "App has #{app.flow_builders.count} flows"
```

## Step 5: Test GraphQL Queries

### Using GraphiQL (if available)

Navigate to `/graphiql` or `/graphql` in your browser (if GraphiQL is enabled).

### Test Visitor Sessions Query

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

### Test Proactive Messages Query

```graphql
query {
  proactiveMessages(appKey: "your-app-key", status: "active") {
    edges {
      node {
        id
        name
        triggerType
        active
        formattedMessage
      }
    }
  }
}
```

### Test Flows Query

```graphql
query {
  flows(appKey: "your-app-key") {
    id
    name
    active
    triggerType
  }
}
```

## Step 6: Test GraphQL Mutations

### Test Track Visitor

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

### Test Create Proactive Campaign

```graphql
mutation {
  createProactiveCampaign(
    appKey: "your-app-key"
    campaignData: {
      name: "Test Campaign"
      triggerType: "time_based"
      delaySeconds: 30
      messageContent: {
        text: "Hello! How can I help you?"
      }
      triggerConditions: {}
      targetingRules: {}
    }
  ) {
    proactiveMessage {
      id
      name
      active
    }
    errors
  }
}
```

### Test Create Flow

```graphql
mutation {
  createFlow(
    appKey: "your-app-key"
    flowData: {
      name: "Test Flow"
      description: "A test flow"
      active: true
      flowData: {
        nodes: []
        connections: []
      }
      triggers: {}
    }
  ) {
    flow {
      id
      name
      active
    }
    errors
  }
}
```

## Troubleshooting

### Migration Fails

If the migration fails:

1. Check PostgreSQL is running:
   ```bash
   docker-compose ps postgres
   ```

2. Check database connection:
   ```bash
   docker-compose run --rm rails bundle exec rails db:version
   ```

3. Check for existing tables:
   ```bash
   docker-compose run --rm rails bundle exec rails runner "puts ActiveRecord::Base.connection.tables.sort"
   ```

### GraphQL Queries Not Found

If GraphQL queries return "field not found":

1. Restart the Rails server:
   ```bash
   docker-compose restart rails
   ```

2. Check that mutations are registered in `app/graphql/types/mutation_type.rb`

3. Check that queries are included in `app/graphql/types/query_type.rb`

### Model Associations Fail

If model associations don't work:

1. Verify models have the correct `belongs_to` and `has_many` declarations
2. Check that foreign keys exist in the database
3. Run the validation script to see specific errors

## Success Criteria

Phase 1 is complete when:

- ✅ All database tables are created
- ✅ All model associations work
- ✅ GraphQL queries can be executed
- ✅ GraphQL mutations can be executed
- ✅ Service objects can be instantiated
- ✅ Basic CRUD operations work for all new models

## Next Steps

Once Phase 1 is validated, proceed to:
- **Phase 2**: Frontend-Backend Integration
- **Phase 3**: Real-time Features
- **Phase 4**: Missing UI Components

