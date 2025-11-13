# frozen_string_literal: true

namespace :tidio do
  desc "Validate Tidio enhancements - Phase 1"
  task validate: :environment do
    puts "\n=== Tidio Enhancement Validation - Phase 1 ===\n\n"
    
    errors = []
    warnings = []
    
    # 1. Check if migration has been run
    puts "1. Checking database tables..."
    required_tables = [
      'visitor_sessions',
      'chat_ratings',
      'flow_builders',
      'proactive_messages',
      'email_sequences',
      'email_sequence_steps',
      'email_sequence_executions',
      'conversation_analytics',
      'typing_indicators',
      'shared_files',
      'contact_lists',
      'contact_list_memberships',
      'widget_themes',
      'push_notifications',
      'webhook_events'
    ]
    
    missing_tables = []
    required_tables.each do |table|
      if ActiveRecord::Base.connection.table_exists?(table)
        puts "  ✓ Table '#{table}' exists"
      else
        missing_tables << table
        errors << "Table '#{table}' does not exist. Run: rails db:migrate"
        puts "  ✗ Table '#{table}' MISSING"
      end
    end
    
    if missing_tables.empty?
      puts "\n  ✓ All required tables exist\n"
    else
      puts "\n  ✗ Missing #{missing_tables.count} table(s). Please run: rails db:migrate\n"
    end
    
    # 2. Check model associations
    puts "2. Checking model associations..."
    
    begin
      app = App.first
      if app.nil?
        warnings << "No apps found. Create an app first to test associations."
        puts "  ⚠ No apps found in database"
      else
        # Test App associations
        puts "  Testing App associations..."
        associations = [
          :visitor_sessions,
          :proactive_messages,
          :flow_builders,
          :email_sequences,
          :contact_lists,
          :widget_themes,
          :push_notifications,
          :webhook_events
        ]
        
        associations.each do |assoc|
          begin
            app.send(assoc)
            puts "    ✓ App##{assoc}"
          rescue => e
            errors << "App##{assoc} association failed: #{e.message}"
            puts "    ✗ App##{assoc} - #{e.message}"
          end
        end
        
        # Test Conversation associations
        conversation = app.conversations.first
        if conversation
          puts "  Testing Conversation associations..."
          conv_associations = [
            :conversation_analytics,
            :chat_ratings,
            :typing_indicators,
            :shared_files
          ]
          
          conv_associations.each do |assoc|
            begin
              conversation.send(assoc)
              puts "    ✓ Conversation##{assoc}"
            rescue => e
              errors << "Conversation##{assoc} association failed: #{e.message}"
              puts "    ✗ Conversation##{assoc} - #{e.message}"
            end
          end
        else
          warnings << "No conversations found. Create a conversation to test associations."
          puts "  ⚠ No conversations found"
        end
      end
    rescue => e
      errors << "Model association check failed: #{e.message}"
      puts "  ✗ Error: #{e.message}"
    end
    
    # 3. Check service objects
    puts "\n3. Checking service objects..."
    
    service_files = [
      'app/services/visitor_tracking_service.rb',
      'app/services/proactive_message_service.rb'
    ]
    
    service_files.each do |file|
      if File.exist?(file)
        puts "  ✓ #{File.basename(file)} exists"
      else
        errors << "Service file missing: #{file}"
        puts "  ✗ #{File.basename(file)} MISSING"
      end
    end
    
    # 4. Check GraphQL types
    puts "\n4. Checking GraphQL types..."
    
    graphql_types = [
      'app/graphql/types/visitor_session_type.rb',
      'app/graphql/types/proactive_message_type.rb',
      'app/graphql/types/flow_builder_type.rb',
      'app/graphql/types/chat_rating_type.rb',
      'app/graphql/types/email_sequence_type.rb',
      'app/graphql/types/conversation_analytics_type.rb',
      'app/graphql/types/typing_indicator_type.rb',
      'app/graphql/types/shared_file_type.rb',
      'app/graphql/types/contact_list_type.rb',
      'app/graphql/types/widget_theme_type.rb',
      'app/graphql/types/push_notification_type.rb',
      'app/graphql/types/webhook_event_type.rb'
    ]
    
    missing_types = []
    graphql_types.each do |type_file|
      if File.exist?(type_file)
        puts "  ✓ #{File.basename(type_file)}"
      else
        missing_types << type_file
        errors << "GraphQL type missing: #{type_file}"
        puts "  ✗ #{File.basename(type_file)} MISSING"
      end
    end
    
    # 5. Check GraphQL mutations
    puts "\n5. Checking GraphQL mutations..."
    
    mutation_files = [
      'app/graphql/mutations/visitor_tracking/track_visitor.rb',
      'app/graphql/mutations/proactive_messages/manage_campaign.rb',
      'app/graphql/mutations/flow_builders/manage_flow.rb',
      'app/graphql/mutations/conversations/rate_conversation.rb'
    ]
    
    mutation_files.each do |file|
      if File.exist?(file)
        puts "  ✓ #{File.basename(File.dirname(file))}/#{File.basename(file)}"
      else
        errors << "Mutation file missing: #{file}"
        puts "  ✗ #{File.basename(File.dirname(file))}/#{File.basename(file)} MISSING"
      end
    end
    
    # 6. Test basic model creation (if tables exist)
    if missing_tables.empty? && app
      puts "\n6. Testing model creation..."
      
      begin
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
        puts "  ✓ VisitorSession created (ID: #{session.id})"
        session.destroy
        
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
        puts "  ✓ ProactiveMessage created (ID: #{message.id})"
        message.destroy
        
        # Test FlowBuilder creation
        flow = app.flow_builders.create!(
          name: 'Test Flow',
          active: true,
          flow_data: { nodes: [], connections: [] },
          triggers: {}
        )
        puts "  ✓ FlowBuilder created (ID: #{flow.id})"
        flow.destroy
        
        puts "\n  ✓ All model creation tests passed"
      rescue => e
        errors << "Model creation test failed: #{e.message}"
        puts "  ✗ Model creation test failed: #{e.message}"
        puts "    #{e.backtrace.first}"
      end
    end
    
    # Summary
    puts "\n" + "="*50
    puts "VALIDATION SUMMARY"
    puts "="*50
    
    if errors.empty? && warnings.empty?
      puts "\n✓ All validations passed! Phase 1 is complete."
      puts "\nNext steps:"
      puts "  1. Test GraphQL queries in GraphiQL/Playground"
      puts "  2. Test GraphQL mutations"
      puts "  3. Verify service objects work correctly"
    else
      if errors.any?
        puts "\n✗ ERRORS FOUND (#{errors.count}):"
        errors.each_with_index do |error, i|
          puts "  #{i+1}. #{error}"
        end
      end
      
      if warnings.any?
        puts "\n⚠ WARNINGS (#{warnings.count}):"
        warnings.each_with_index do |warning, i|
          puts "  #{i+1}. #{warning}"
        end
      end
      
      puts "\nPlease fix the errors above before proceeding."
    end
    
    puts "\n" + "="*50 + "\n"
    
    exit(errors.any? ? 1 : 0)
  end
  
  desc "Test GraphQL schema loading"
  task test_graphql: :environment do
    puts "\n=== Testing GraphQL Schema ===\n\n"
    
    begin
      schema = ChaskiqSchema
      puts "✓ GraphQL schema loaded successfully"
      
      # Check if our new queries exist
      query_type = schema.types['Query']
      if query_type
        puts "✓ Query type found"
        
        # Check for visitor tracking queries
        visitor_queries = ['visitorSessions', 'liveVisitors', 'visitorAnalytics']
        visitor_queries.each do |query_name|
          field = query_type.fields[query_name]
          if field
            puts "  ✓ Query '#{query_name}' registered"
          else
            puts "  ✗ Query '#{query_name}' NOT found"
          end
        end
        
        # Check for proactive message queries
        proactive_queries = ['proactiveMessages', 'proactiveMessage', 'proactiveMessageAnalytics']
        proactive_queries.each do |query_name|
          field = query_type.fields[query_name]
          if field
            puts "  ✓ Query '#{query_name}' registered"
          else
            puts "  ✗ Query '#{query_name}' NOT found"
          end
        end
        
        # Check for flow builder queries
        flow_queries = ['flows', 'flow', 'flowAnalytics']
        flow_queries.each do |query_name|
          field = query_type.fields[query_name]
          if field
            puts "  ✓ Query '#{query_name}' registered"
          else
            puts "  ✗ Query '#{query_name}' NOT found"
          end
        end
      end
      
      # Check mutations
      mutation_type = schema.types['Mutation']
      if mutation_type
        puts "\n✓ Mutation type found"
        
        tidio_mutations = [
          'trackVisitor',
          'updateVisitorActivity',
          'trackEvent',
          'createProactiveCampaign',
          'updateProactiveCampaign',
          'createFlow',
          'updateFlow',
          'rateConversation'
        ]
        
        tidio_mutations.each do |mutation_name|
          field = mutation_type.fields[mutation_name]
          if field
            puts "  ✓ Mutation '#{mutation_name}' registered"
          else
            puts "  ✗ Mutation '#{mutation_name}' NOT found"
          end
        end
      end
      
      puts "\n✓ GraphQL schema test complete\n"
    rescue => e
      puts "✗ GraphQL schema test failed: #{e.message}"
      puts e.backtrace.first(5).join("\n")
      exit(1)
    end
  end
end

