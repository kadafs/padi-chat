#!/usr/bin/env ruby
# frozen_string_literal: true

# Simple code structure validation that doesn't require Rails/bundle
# Run with: ruby validate_code_structure.rb

puts "\n=== Tidio Code Structure Validation (No Rails Required) ===\n\n"

errors = []
warnings = []
success_count = 0

# Helper to check file exists
def check_file(path, name, errors, warnings, success_count)
  if File.exist?(path)
    puts "  ✓ #{name}"
    success_count + 1
  else
    errors << "#{name} missing: #{path}"
    puts "  ✗ #{name} MISSING: #{path}"
    success_count
  end
end

# 1. Check migration file
puts "1. Checking migration file..."
migration_file = 'db/migrate/20241112000001_create_tidio_enhancements.rb'
if File.exist?(migration_file)
  puts "  ✓ Migration file exists"
  # Check syntax
  result = system("ruby -c \"#{migration_file}\" >nul 2>&1")
  if result
    puts "  ✓ Migration syntax valid"
    success_count += 1
  else
    errors << "Migration syntax error"
    puts "  ✗ Migration syntax error"
  end
else
  errors << "Migration file missing"
  puts "  ✗ Migration file MISSING"
end

# 2. Check model files
puts "\n2. Checking model files..."
models = {
  'app/models/visitor_session.rb' => 'VisitorSession',
  'app/models/proactive_message.rb' => 'ProactiveMessage',
  'app/models/flow_builder.rb' => 'FlowBuilder',
  'app/models/chat_rating.rb' => 'ChatRating',
  'app/models/email_sequence.rb' => 'EmailSequence',
  'app/models/email_sequence_step.rb' => 'EmailSequenceStep',
  'app/models/email_sequence_execution.rb' => 'EmailSequenceExecution',
  'app/models/conversation_analytics.rb' => 'ConversationAnalytics',
  'app/models/typing_indicator.rb' => 'TypingIndicator',
  'app/models/shared_file.rb' => 'SharedFile',
  'app/models/contact_list.rb' => 'ContactList',
  'app/models/contact_list_membership.rb' => 'ContactListMembership',
  'app/models/widget_theme.rb' => 'WidgetTheme',
  'app/models/push_notification.rb' => 'PushNotification',
  'app/models/webhook_event.rb' => 'WebhookEvent'
}

models.each do |path, name|
  if File.exist?(path)
    puts "  ✓ #{name}"
    success_count += 1
  else
    errors << "#{name} model missing: #{path}"
    puts "  ✗ #{name} MISSING"
  end
end

# 3. Check service objects
puts "\n3. Checking service objects..."
services = {
  'app/services/visitor_tracking_service.rb' => 'VisitorTrackingService',
  'app/services/proactive_message_service.rb' => 'ProactiveMessageService'
}

services.each do |path, name|
  if File.exist?(path)
    puts "  ✓ #{name}"
    success_count += 1
  else
    errors << "#{name} missing: #{path}"
    puts "  ✗ #{name} MISSING"
  end
end

# 4. Check GraphQL types
puts "\n4. Checking GraphQL types..."
graphql_types = {
  'app/graphql/types/visitor_session_type.rb' => 'VisitorSessionType',
  'app/graphql/types/proactive_message_type.rb' => 'ProactiveMessageType',
  'app/graphql/types/flow_builder_type.rb' => 'FlowBuilderType',
  'app/graphql/types/chat_rating_type.rb' => 'ChatRatingType',
  'app/graphql/types/email_sequence_type.rb' => 'EmailSequenceType',
  'app/graphql/types/email_sequence_step_type.rb' => 'EmailSequenceStepType',
  'app/graphql/types/email_sequence_execution_type.rb' => 'EmailSequenceExecutionType',
  'app/graphql/types/conversation_analytics_type.rb' => 'ConversationAnalyticsType',
  'app/graphql/types/typing_indicator_type.rb' => 'TypingIndicatorType',
  'app/graphql/types/shared_file_type.rb' => 'SharedFileType',
  'app/graphql/types/contact_list_type.rb' => 'ContactListType',
  'app/graphql/types/contact_list_membership_type.rb' => 'ContactListMembershipType',
  'app/graphql/types/widget_theme_type.rb' => 'WidgetThemeType',
  'app/graphql/types/push_notification_type.rb' => 'PushNotificationType',
  'app/graphql/types/webhook_event_type.rb' => 'WebhookEventType'
}

graphql_types.each do |path, name|
  if File.exist?(path)
    puts "  ✓ #{name}"
    success_count += 1
  else
    errors << "#{name} missing: #{path}"
    puts "  ✗ #{name} MISSING"
  end
end

# 5. Check GraphQL mutations
puts "\n5. Checking GraphQL mutations..."
mutations = {
  'app/graphql/mutations/visitor_tracking/track_visitor.rb' => 'TrackVisitor',
  'app/graphql/mutations/proactive_messages/manage_campaign.rb' => 'ManageCampaign',
  'app/graphql/mutations/flow_builders/manage_flow.rb' => 'ManageFlow',
  'app/graphql/mutations/conversations/rate_conversation.rb' => 'RateConversation'
}

mutations.each do |path, name|
  if File.exist?(path)
    puts "  ✓ #{name}"
    success_count += 1
  else
    errors << "#{name} mutation missing: #{path}"
    puts "  ✗ #{name} MISSING"
  end
end

# 6. Check GraphQL queries
puts "\n6. Checking GraphQL query extensions..."
queries = {
  'app/graphql/types/query_type_extensions/visitor_tracking_queries.rb' => 'VisitorTrackingQueries',
  'app/graphql/types/query_type_extensions/proactive_message_queries.rb' => 'ProactiveMessageQueries',
  'app/graphql/types/query_type_extensions/flow_builder_queries.rb' => 'FlowBuilderQueries'
}

queries.each do |path, name|
  if File.exist?(path)
    puts "  ✓ #{name}"
    success_count += 1
  else
    errors << "#{name} missing: #{path}"
    puts "  ✗ #{name} MISSING"
  end
end

# 7. Check background jobs
puts "\n7. Checking background jobs..."
jobs = {
  'app/jobs/flow_execution_job.rb' => 'FlowExecutionJob',
  'app/jobs/flow_continuation_job.rb' => 'FlowContinuationJob',
  'app/jobs/email_sequence_step_job.rb' => 'EmailSequenceStepJob',
  'app/jobs/email_sender_job.rb' => 'EmailSenderJob',
  'app/jobs/webhook_sender_job.rb' => 'WebhookSenderJob'
}

jobs.each do |path, name|
  if File.exist?(path)
    puts "  ✓ #{name}"
    success_count += 1
  else
    errors << "#{name} missing: #{path}"
    puts "  ✗ #{name} MISSING"
  end
end

# 8. Check frontend files
puts "\n8. Checking frontend components..."
frontend_files = {
  'app/javascript/src/pages/TidioInbox.tsx' => 'TidioInbox',
  'app/javascript/src/pages/FlowBuilder.tsx' => 'FlowBuilder',
  'app/javascript/src/pages/VisitorTracking.tsx' => 'VisitorTracking'
}

frontend_files.each do |path, name|
  if File.exist?(path)
    puts "  ✓ #{name}"
    success_count += 1
  else
    warnings << "#{name} component missing: #{path}"
    puts "  ⚠ #{name} MISSING"
  end
end

# 9. Check frontend GraphQL definitions
puts "\n9. Checking frontend GraphQL definitions..."
queries_file = 'app/javascript/packages/store/src/graphql/queries.ts'
mutations_file = 'app/javascript/packages/store/src/graphql/mutations.ts'

if File.exist?(queries_file)
  content = File.read(queries_file)
  required_queries = ['VISITOR_SESSIONS', 'LIVE_VISITORS', 'PROACTIVE_MESSAGES', 'FLOWS']
  required_queries.each do |query|
    if content.include?("export const #{query}")
      puts "  ✓ Query #{query} defined"
      success_count += 1
    else
      errors << "Query #{query} not found in queries.ts"
      puts "  ✗ Query #{query} NOT found"
    end
  end
else
  errors << "Frontend queries file missing"
  puts "  ✗ queries.ts MISSING"
end

if File.exist?(mutations_file)
  content = File.read(mutations_file)
  required_mutations = ['TRACK_VISITOR', 'CREATE_PROACTIVE_CAMPAIGN', 'CREATE_FLOW', 'RATE_CONVERSATION']
  required_mutations.each do |mutation|
    if content.include?("export const #{mutation}")
      puts "  ✓ Mutation #{mutation} defined"
      success_count += 1
    else
      errors << "Mutation #{mutation} not found in mutations.ts"
      puts "  ✗ Mutation #{mutation} NOT found"
    end
  end
else
  errors << "Frontend mutations file missing"
  puts "  ✗ mutations.ts MISSING"
end

# 10. Check routes
puts "\n10. Checking routes..."
routes_file = 'app/javascript/src/pages/AppContainer.tsx'
if File.exist?(routes_file)
  content = File.read(routes_file)
  required_routes = ['tidio/inbox', 'tidio/visitors', 'tidio/flows']
  required_routes.each do |route|
    if content.include?(route)
      puts "  ✓ Route /#{route} defined"
      success_count += 1
    else
      warnings << "Route /#{route} not found in AppContainer"
      puts "  ⚠ Route /#{route} NOT found"
    end
  end
else
  warnings << "AppContainer.tsx missing"
  puts "  ⚠ AppContainer.tsx MISSING"
end

# Summary
puts "\n" + "="*60
puts "CODE STRUCTURE VALIDATION SUMMARY"
puts "="*60
puts "\nFiles checked: #{success_count}"
puts "Errors: #{errors.count}"
puts "Warnings: #{warnings.count}"

if errors.empty?
  puts "\n✓ All critical files exist!"
  puts "\nCode structure is valid. Next steps:"
  puts "  1. Install PostgreSQL development libraries (see PHASE1_WINDOWS_SETUP.md)"
  puts "  2. Run: bundle install"
  puts "  3. Run: bundle exec rails db:migrate"
  puts "  4. Run: bundle exec rails tidio:validate (full validation)"
else
  puts "\n✗ ERRORS FOUND (#{errors.count}):"
  errors.first(10).each_with_index do |error, i|
    puts "  #{i+1}. #{error}"
  end
  puts "  ... (#{errors.count - 10} more)" if errors.count > 10
end

if warnings.any?
  puts "\n⚠ WARNINGS (#{warnings.count}):"
  warnings.first(5).each_with_index do |warning, i|
    puts "  #{i+1}. #{warning}"
  end
end

puts "\n" + "="*60 + "\n"

exit(errors.any? ? 1 : 0)

