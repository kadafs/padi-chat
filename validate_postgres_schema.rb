#!/usr/bin/env ruby
# frozen_string_literal: true

# Direct PostgreSQL schema validation for Tidio enhancements
# This script connects directly to PostgreSQL and validates the schema
# without requiring Rails or all gems to be installed

require 'pg'

puts "\n=== Tidio PostgreSQL Schema Validation ===\n\n"

# Database connection configuration
# Try to read from config/database.yml or use defaults
db_config = {
  host: ENV['DB_HOST'] || 'localhost',
  port: ENV['DB_PORT'] || 5432,
  dbname: ENV['DB_NAME'] || ENV['POSTGRES_DATABASE'] || 'chaskiq_dev',
  user: ENV['DB_USER'] || 'postgres',
  password: ENV['DB_PASSWORD'] || ''
}

# Try to read from database.yml if it exists
if File.exist?('config/database.yml')
  require 'yaml'
  begin
    yaml_config = YAML.load_file('config/database.yml')
    dev_config = yaml_config['development'] || yaml_config['default']
    if dev_config
      db_config[:host] = dev_config['host'] || db_config[:host]
      db_config[:port] = dev_config['port'] || db_config[:port]
      db_config[:dbname] = dev_config['database'] || db_config[:dbname]
      db_config[:user] = dev_config['username'] || db_config[:user]
      db_config[:password] = dev_config['password'] || db_config[:password]
    end
  rescue => e
    puts "⚠ Could not read config/database.yml: #{e.message}"
    puts "Using default connection settings...\n"
  end
end

errors = []
warnings = []
success_count = 0

begin
  # Connect to PostgreSQL
  puts "Connecting to PostgreSQL..."
  puts "  Host: #{db_config[:host]}"
  puts "  Port: #{db_config[:port]}"
  puts "  Database: #{db_config[:dbname]}"
  puts "  User: #{db_config[:user]}\n\n"

  conn = PG.connect(db_config)

  # List of tables that should exist for Tidio enhancements
  required_tables = [
    'visitor_sessions',
    'proactive_messages',
    'flow_builders',
    'chat_ratings',
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

  # Check if tables exist
  puts "1. Checking required tables..."
  existing_tables = conn.exec("
    SELECT table_name 
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_type = 'BASE TABLE'
  ").map { |row| row['table_name'] }

  required_tables.each do |table|
    if existing_tables.include?(table)
      puts "  ✓ #{table}"
      success_count += 1
    else
      errors << "Table #{table} does not exist"
      puts "  ✗ #{table} MISSING"
    end
  end

  # Check for required columns in existing tables
  puts "\n2. Checking required columns in existing tables..."

  # Check visitor_sessions columns
  if existing_tables.include?('visitor_sessions')
    columns = conn.exec("
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'visitor_sessions'
    ").map { |row| row['column_name'] }
    
    required_columns = ['session_id', 'app_id', 'app_user_id', 'referrer_url', 'landing_page', 'current_page', 'device_type', 'browser', 'os', 'country_code', 'city', 'page_views', 'time_on_site', 'is_returning', 'first_seen_at', 'last_activity_at']
    required_columns.each do |col|
      if columns.include?(col)
        puts "  ✓ visitor_sessions.#{col}"
        success_count += 1
      else
        errors << "Column visitor_sessions.#{col} does not exist"
        puts "  ✗ visitor_sessions.#{col} MISSING"
      end
    end
  end

  # Check proactive_messages columns
  if existing_tables.include?('proactive_messages')
    columns = conn.exec("
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'proactive_messages'
    ").map { |row| row['column_name'] }
    
    required_columns = ['app_id', 'name', 'message', 'trigger_type', 'trigger_conditions', 'targeting_rules', 'is_active', 'priority', 'schedule']
    required_columns.each do |col|
      if columns.include?(col)
        puts "  ✓ proactive_messages.#{col}"
        success_count += 1
      else
        errors << "Column proactive_messages.#{col} does not exist"
        puts "  ✗ proactive_messages.#{col} MISSING"
      end
    end
  end

  # Check flow_builders columns
  if existing_tables.include?('flow_builders')
    columns = conn.exec("
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'flow_builders'
    ").map { |row| row['column_name'] }
    
    required_columns = ['app_id', 'name', 'description', 'flow_data', 'trigger_type', 'trigger_conditions', 'is_active']
    required_columns.each do |col|
      if columns.include?(col)
        puts "  ✓ flow_builders.#{col}"
        success_count += 1
      else
        errors << "Column flow_builders.#{col} does not exist"
        puts "  ✗ flow_builders.#{col} MISSING"
      end
    end
  end

  # Check indexes
  puts "\n3. Checking indexes..."
  indexes = conn.exec("
    SELECT indexname 
    FROM pg_indexes 
    WHERE schemaname = 'public'
  ").map { |row| row['indexname'] }

  required_indexes = [
    'index_visitor_sessions_on_app_id',
    'index_visitor_sessions_on_app_user_id',
    'index_visitor_sessions_on_session_id',
    'index_proactive_messages_on_app_id',
    'index_flow_builders_on_app_id',
    'index_chat_ratings_on_conversation_id',
    'index_email_sequences_on_app_id'
  ]

  required_indexes.each do |index|
    if indexes.include?(index)
      puts "  ✓ #{index}"
      success_count += 1
    else
      warnings << "Index #{index} does not exist (may be created automatically)"
      puts "  ⚠ #{index} NOT FOUND"
    end
  end

  # Check foreign keys
  puts "\n4. Checking foreign key constraints..."
  foreign_keys = conn.exec("
    SELECT
      tc.table_name, 
      kcu.column_name, 
      ccu.table_name AS foreign_table_name,
      ccu.column_name AS foreign_column_name 
    FROM information_schema.table_constraints AS tc 
    JOIN information_schema.key_column_usage AS kcu
      ON tc.constraint_name = kcu.constraint_name
    JOIN information_schema.constraint_column_usage AS ccu
      ON ccu.constraint_name = tc.constraint_name
    WHERE constraint_type = 'FOREIGN KEY'
    AND tc.table_schema = 'public'
  ")

  fk_count = 0
  foreign_keys.each do |fk|
    if required_tables.include?(fk['table_name']) || required_tables.include?(fk['foreign_table_name'])
      fk_count += 1
    end
  end

  if fk_count > 0
    puts "  ✓ Found #{fk_count} foreign key constraints on Tidio tables"
    success_count += 1
  else
    warnings << "No foreign key constraints found (may be added by migration)"
    puts "  ⚠ No foreign keys found"
  end

  # Summary
  puts "\n" + "="*60
  puts "POSTGRESQL SCHEMA VALIDATION SUMMARY"
  puts "="*60
  puts "\nChecks passed: #{success_count}"
  puts "Errors: #{errors.count}"
  puts "Warnings: #{warnings.count}"

  if errors.empty?
    puts "\n✓ All critical database structures are in place!"
    puts "\nNext steps:"
    puts "  1. Run: bundle exec rails db:migrate (if not already done)"
    puts "  2. Run: bundle exec rails tidio:validate (full validation)"
    exit_code = 0
  else
    puts "\n✗ ERRORS FOUND (#{errors.count}):"
    errors.first(10).each_with_index do |error, i|
      puts "  #{i+1}. #{error}"
    end
    puts "  ... (#{errors.count - 10} more)" if errors.count > 10
    puts "\n⚠ To fix: Run 'bundle exec rails db:migrate' to create missing tables/columns"
    exit_code = 1
  end

  if warnings.any?
    puts "\n⚠ WARNINGS (#{warnings.count}):"
    warnings.first(5).each_with_index do |warning, i|
      puts "  #{i+1}. #{warning}"
    end
  end

  puts "\n" + "="*60 + "\n"

  conn.close
  exit(exit_code)

rescue PG::ConnectionBad => e
  puts "\n✗ Could not connect to PostgreSQL: #{e.message}"
  puts "\nPlease ensure:"
  puts "  1. PostgreSQL is running"
  puts "  2. Database '#{db_config[:dbname]}' exists"
  puts "  3. User '#{db_config[:user]}' has access"
  puts "  4. Connection settings are correct"
  puts "\nYou can set connection details via environment variables:"
  puts "  DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD"
  exit(1)
rescue LoadError => e
  puts "\n✗ Could not load 'pg' gem: #{e.message}"
  puts "\nPlease install the pg gem:"
  puts "  gem install pg"
  exit(1)
rescue => e
  puts "\n✗ Unexpected error: #{e.message}"
  puts e.backtrace.first(5).join("\n")
  exit(1)
end

