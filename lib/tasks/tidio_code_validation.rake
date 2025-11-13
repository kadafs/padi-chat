# frozen_string_literal: true

namespace :tidio do
  desc "Validate Tidio code structure (no database required)"
  task validate_code: :environment do
    puts "\n=== Tidio Code Structure Validation ===\n\n"
    
    errors = []
    warnings = []
    
    # 1. Check migration file exists
    puts "1. Checking migration file..."
    migration_file = 'db/migrate/20241112000001_create_tidio_enhancements.rb'
    if File.exist?(migration_file)
      puts "  ✓ Migration file exists"
      
      # Check migration syntax
      begin
        load migration_file
        puts "  ✓ Migration syntax is valid"
      rescue => e
        errors << "Migration syntax error: #{e.message}"
        puts "  ✗ Migration syntax error: #{e.message}"
      end
    else
      errors << "Migration file missing: #{migration_file}"
      puts "  ✗ Migration file MISSING"
    end
    
    # 2. Check model files
    puts "\n2. Checking model files..."
    models = [
      'app/models/visitor_session.rb',
      'app/models/proactive_message.rb',
      'app/models/flow_builder.rb',
      'app/models/chat_rating.rb',
      'app/models/email_sequence.rb',
      'app/models/email_sequence_step.rb',
      'app/models/email_sequence_execution.rb',
      'app/models/conversation_analytics.rb',
      'app/models/typing_indicator.rb',
      'app/models/shared_file.rb',
      'app/models/contact_list.rb',
      'app/models/contact_list_membership.rb',
      'app/models/widget_theme.rb',
      'app/models/push_notification.rb',
      'app/models/webhook_event.rb'
    ]
    
    missing_models = []
    models.each do |model_file|
      if File.exist?(model_file)
        puts "  ✓ #{File.basename(model_file)}"
        
        # Try to load and check syntax
        begin
          load model_file
          puts "    ✓ Syntax valid"
        rescue => e
          warnings << "#{model_file} syntax warning: #{e.message}"
          puts "    ⚠ Syntax warning: #{e.message}"
        end
      else
        missing_models << model_file
        errors << "Model file missing: #{model_file}"
        puts "  ✗ #{File.basename(model_file)} MISSING"
      end
    end
    
    # 3. Check service objects
    puts "\n3. Checking service objects..."
    services = [
      'app/services/visitor_tracking_service.rb',
      'app/services/proactive_message_service.rb'
    ]
    
    services.each do |service_file|
      if File.exist?(service_file)
        puts "  ✓ #{File.basename(service_file)}"
      else
        errors << "Service file missing: #{service_file}"
        puts "  ✗ #{File.basename(service_file)} MISSING"
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
      'app/graphql/types/email_sequence_step_type.rb',
      'app/graphql/types/email_sequence_execution_type.rb',
      'app/graphql/types/conversation_analytics_type.rb',
      'app/graphql/types/typing_indicator_type.rb',
      'app/graphql/types/shared_file_type.rb',
      'app/graphql/types/contact_list_type.rb',
      'app/graphql/types/contact_list_membership_type.rb',
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
    mutations = [
      'app/graphql/mutations/visitor_tracking/track_visitor.rb',
      'app/graphql/mutations/proactive_messages/manage_campaign.rb',
      'app/graphql/mutations/flow_builders/manage_flow.rb',
      'app/graphql/mutations/conversations/rate_conversation.rb'
    ]
    
    mutations.each do |mutation_file|
      if File.exist?(mutation_file)
        puts "  ✓ #{File.basename(File.dirname(mutation_file))}/#{File.basename(mutation_file)}"
      else
        errors << "Mutation file missing: #{mutation_file}"
        puts "  ✗ #{File.basename(File.dirname(mutation_file))}/#{File.basename(mutation_file)} MISSING"
      end
    end
    
    # 6. Check GraphQL queries
    puts "\n6. Checking GraphQL query extensions..."
    queries = [
      'app/graphql/types/query_type_extensions/visitor_tracking_queries.rb',
      'app/graphql/types/query_type_extensions/proactive_message_queries.rb',
      'app/graphql/types/query_type_extensions/flow_builder_queries.rb'
    ]
    
    queries.each do |query_file|
      if File.exist?(query_file)
        puts "  ✓ #{File.basename(query_file)}"
      else
        errors << "Query extension missing: #{query_file}"
        puts "  ✗ #{File.basename(query_file)} MISSING"
      end
    end
    
    # 7. Check background jobs
    puts "\n7. Checking background jobs..."
    jobs = [
      'app/jobs/flow_execution_job.rb',
      'app/jobs/flow_continuation_job.rb',
      'app/jobs/email_sequence_step_job.rb',
      'app/jobs/email_sender_job.rb',
      'app/jobs/webhook_sender_job.rb'
    ]
    
    jobs.each do |job_file|
      if File.exist?(job_file)
        puts "  ✓ #{File.basename(job_file)}"
      else
        errors << "Job file missing: #{job_file}"
        puts "  ✗ #{File.basename(job_file)} MISSING"
      end
    end
    
    # 8. Check frontend components
    puts "\n8. Checking frontend components..."
    frontend_files = [
      'app/javascript/src/pages/TidioInbox.tsx',
      'app/javascript/src/pages/FlowBuilder.tsx',
      'app/javascript/src/pages/VisitorTracking.tsx'
    ]
    
    frontend_files.each do |file|
      if File.exist?(file)
        puts "  ✓ #{File.basename(file)}"
      else
        warnings << "Frontend file missing: #{file}"
        puts "  ⚠ #{File.basename(file)} MISSING"
      end
    end
    
    # 9. Check GraphQL query/mutation definitions
    puts "\n9. Checking GraphQL query/mutation definitions..."
    
    queries_file = 'app/javascript/packages/store/src/graphql/queries.ts'
    mutations_file = 'app/javascript/packages/store/src/graphql/mutations.ts'
    
    if File.exist?(queries_file)
      content = File.read(queries_file)
      required_queries = ['VISITOR_SESSIONS', 'LIVE_VISITORS', 'PROACTIVE_MESSAGES', 'FLOWS']
      required_queries.each do |query|
        if content.include?("export const #{query}")
          puts "  ✓ Query #{query} defined"
        else
          errors << "Query #{query} not found in queries.ts"
          puts "  ✗ Query #{query} NOT found"
        end
      end
    else
      errors << "Frontend queries file missing: #{queries_file}"
      puts "  ✗ queries.ts MISSING"
    end
    
    if File.exist?(mutations_file)
      content = File.read(mutations_file)
      required_mutations = ['TRACK_VISITOR', 'CREATE_PROACTIVE_CAMPAIGN', 'CREATE_FLOW', 'RATE_CONVERSATION']
      required_mutations.each do |mutation|
        if content.include?("export const #{mutation}")
          puts "  ✓ Mutation #{mutation} defined"
        else
          errors << "Mutation #{mutation} not found in mutations.ts"
          puts "  ✗ Mutation #{mutation} NOT found"
        end
      end
    else
      errors << "Frontend mutations file missing: #{mutations_file}"
      puts "  ✗ mutations.ts MISSING"
    end
    
    # Summary
    puts "\n" + "="*50
    puts "CODE STRUCTURE VALIDATION SUMMARY"
    puts "="*50
    
    if errors.empty? && warnings.empty?
      puts "\n✓ All code structure validations passed!"
      puts "\nNext steps:"
      puts "  1. Install PostgreSQL development libraries"
      puts "  2. Run: bundle install"
      puts "  3. Run: bundle exec rails db:migrate"
      puts "  4. Run: bundle exec rails tidio:validate (full validation)"
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
      
      puts "\nPlease fix the errors above."
    end
    
    puts "\n" + "="*50 + "\n"
    
    exit(errors.any? ? 1 : 0)
  end
end

