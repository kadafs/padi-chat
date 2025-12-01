# frozen_string_literal: true

class CreateTidioEnhancements < ActiveRecord::Migration[7.0]
  def up
    # Enhanced Visitor Tracking (Tidio-like)
    create_table :visitor_sessions, if_not_exists: true do |t|
      t.references :app, null: false, foreign_key: true
      t.references :app_user, null: false, foreign_key: true
      t.string :session_id, null: false
      t.string :referrer_url, limit: 2000
      t.string :landing_page, limit: 2000
      t.string :current_page, limit: 2000
      t.jsonb :utm_parameters, default: {}
      t.string :device_type # desktop, tablet, mobile
      t.string :browser
      t.string :os
      t.string :country_code
      t.string :city
      t.inet :ip_address
      t.jsonb :geolocation, default: {}
      t.integer :page_views, default: 1
      t.integer :time_on_site, default: 0 # seconds
      t.boolean :is_returning, default: false
      t.timestamp :first_seen_at
      t.timestamp :last_activity_at
      t.jsonb :custom_attributes, default: {}
      t.timestamps
    end

    # Advanced Chat Features
    create_table :chat_ratings, if_not_exists: true do |t|
      t.references :conversation, null: false, foreign_key: true
      t.references :app_user, null: false, foreign_key: true
      t.references :agent, null: true, foreign_key: true
      t.integer :rating, null: false # 1-5 stars
      t.text :feedback
      t.string :rating_type # conversation, agent, overall
      t.timestamps
    end

    # Enhanced Bot Builder (Visual Flow Builder)
    create_table :flow_builders, if_not_exists: true do |t|
      t.references :app, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.jsonb :flow_data, default: {} # Visual flow configuration
      t.jsonb :triggers, default: {} # When to trigger this flow
      t.boolean :active, default: true
      t.string :flow_type # welcome, qualifying, support, etc.
      t.integer :position, default: 0
      t.timestamps
    end

    # Proactive Chat (Tidio's key feature)
    create_table :proactive_messages, if_not_exists: true do |t|
      t.references :app, null: false, foreign_key: true
      t.string :name, null: false
      t.jsonb :trigger_conditions, default: {} # time_on_page, pages_visited, etc.
      t.jsonb :message_content, default: {}
      t.jsonb :targeting_rules, default: {} # visitor segments, geo, device, etc.
      t.boolean :active, default: true
      t.integer :delay_seconds, default: 30
      t.string :trigger_type # time_based, behavior_based, exit_intent
      t.integer :priority, default: 0
      t.datetime :start_date
      t.datetime :end_date
      t.jsonb :schedule, default: {} # business hours, days of week
      t.timestamps
    end

    # Enhanced Email Marketing (Tidio Email)
    create_table :email_sequences, if_not_exists: true do |t|
      t.references :app, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.jsonb :sequence_data, default: {} # Email flow configuration
      t.string :trigger_event # signup, purchase, abandon_cart, etc.
      t.boolean :active, default: true
      t.timestamps
    end

    create_table :email_sequence_steps, if_not_exists: true do |t|
      t.references :email_sequence, null: false, foreign_key: true
      t.string :name, null: false
      t.text :subject_line
      t.text :content
      t.integer :delay_days, default: 0
      t.integer :delay_hours, default: 0
      t.integer :step_order, null: false
      t.boolean :active, default: true
      t.timestamps
    end

    create_table :email_sequence_executions, if_not_exists: true do |t|
      t.references :email_sequence, null: false, foreign_key: true
      t.references :app_user, null: false, foreign_key: true
      t.string :status, default: 'started' # started, in_progress, completed, cancelled, failed
      t.jsonb :context, default: {}
      t.timestamp :started_at
      t.timestamp :completed_at
      t.text :error_message
      t.timestamps
    end

    # Advanced Analytics
    create_table :conversation_analytics, if_not_exists: true do |t|
      t.references :conversation, null: false, foreign_key: true, index: { unique: true }
      t.timestamp :first_response_at
      t.integer :first_response_time_seconds
      t.timestamp :resolution_at
      t.integer :resolution_time_seconds
      t.integer :agent_messages_count, default: 0
      t.integer :customer_messages_count, default: 0
      t.integer :bot_messages_count, default: 0
      t.boolean :escalated_to_human, default: false
      t.integer :rating
      t.text :tags, array: true, default: []
      t.timestamps
    end

    # Live Typing Indicators
    create_table :typing_indicators, if_not_exists: true do |t|
      t.references :conversation, null: false, foreign_key: true
      t.references :user, polymorphic: true # Agent or AppUser
      t.timestamp :started_typing_at
      t.timestamp :stopped_typing_at
      t.boolean :is_typing, default: false
      t.timestamps
    end

    # File Sharing Enhancements
    create_table :shared_files, if_not_exists: true do |t|
      t.references :conversation, null: false, foreign_key: true
      t.references :sender, polymorphic: true # Agent or AppUser
      t.string :file_name, null: false
      t.string :file_type
      t.integer :file_size
      t.string :file_url
      t.string :thumbnail_url
      t.boolean :is_image, default: false
      t.boolean :is_document, default: false
      t.jsonb :metadata, default: {}
      t.timestamps
    end

    # Enhanced Contact Management
    create_table :contact_lists, if_not_exists: true do |t|
      t.references :app, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.jsonb :filter_criteria, default: {}
      t.boolean :is_dynamic, default: false # auto-updating based on criteria
      t.integer :contacts_count, default: 0
      t.timestamps
    end

    create_table :contact_list_memberships, if_not_exists: true do |t|
      t.references :contact_list, null: false, foreign_key: true
      t.references :app_user, null: false, foreign_key: true
      t.timestamp :added_at
      t.timestamps
    end

    # Enhanced Widget Customization
    create_table :widget_themes, if_not_exists: true do |t|
      t.references :app, null: false, foreign_key: true
      t.string :name, null: false
      t.jsonb :theme_config, default: {} # colors, fonts, animations, etc.
      t.boolean :is_active, default: false
      t.boolean :is_default, default: false
      t.timestamps
    end

    # Mobile App Push Notifications
    create_table :push_notifications, if_not_exists: true do |t|
      t.references :app, null: false, foreign_key: true
      t.references :agent, null: true, foreign_key: true
      t.string :title, null: false
      t.text :body
      t.string :notification_type # new_conversation, mention, etc.
      t.jsonb :payload, default: {}
      t.boolean :sent, default: false
      t.timestamp :sent_at
      t.string :device_tokens, array: true, default: []
      t.timestamps
    end

    # Integration Enhancements
    create_table :webhook_events, if_not_exists: true do |t|
      t.references :app, null: false, foreign_key: true
      t.string :event_type, null: false
      t.jsonb :payload, default: {}
      t.string :webhook_url
      t.integer :attempts, default: 0
      t.boolean :delivered, default: false
      t.timestamp :delivered_at
      t.text :error_message
      t.timestamps
    end

    # Add indexes for performance (only if they don't exist)
    add_index :visitor_sessions, :session_id unless index_exists?(:visitor_sessions, :session_id)
    add_index :visitor_sessions, [:app_id, :session_id] unless index_exists?(:visitor_sessions, [:app_id, :session_id])
    add_index :visitor_sessions, :last_activity_at unless index_exists?(:visitor_sessions, :last_activity_at)
    add_index :proactive_messages, [:app_id, :active] unless index_exists?(:proactive_messages, [:app_id, :active])
    unless index_exists?(:typing_indicators, [:conversation_id, :user_type, :user_id], name: 'index_typing_indicators_on_conversation_and_user')
      add_index :typing_indicators, [:conversation_id, :user_type, :user_id],
        name: 'index_typing_indicators_on_conversation_and_user'
    end
    unless index_exists?(:contact_list_memberships, [:contact_list_id, :app_user_id], name: 'idx_contact_list_memberships_on_contact_and_user')
      add_index :contact_list_memberships, [:contact_list_id, :app_user_id],
        unique: true,
        name: 'idx_contact_list_memberships_on_contact_and_user'
    end
    add_index :webhook_events, [:app_id, :event_type] unless index_exists?(:webhook_events, [:app_id, :event_type])
    add_index :webhook_events, :delivered unless index_exists?(:webhook_events, :delivered)

    # Add columns to existing tables (only if they don't exist)
    add_column :apps, :tidio_features, :jsonb, default: {} unless column_exists?(:apps, :tidio_features)
    add_column :conversations, :conversation_rating, :integer unless column_exists?(:conversations, :conversation_rating)
    add_column :conversations, :resolution_time_seconds, :integer unless column_exists?(:conversations, :resolution_time_seconds)
    add_column :conversations, :customer_satisfaction_score, :integer unless column_exists?(:conversations, :customer_satisfaction_score)
    add_column :app_users, :total_conversations, :integer, default: 0 unless column_exists?(:app_users, :total_conversations)
    add_column :app_users, :last_contacted_at, :timestamp unless column_exists?(:app_users, :last_contacted_at)
    add_column :app_users, :lead_score, :integer, default: 0 unless column_exists?(:app_users, :lead_score)
    add_column :app_users, :lifecycle_stage, :string unless column_exists?(:app_users, :lifecycle_stage) # visitor, lead, customer, etc.
    add_column :agents, :online_status, :string, default: 'offline' unless column_exists?(:agents, :online_status) # online, away, busy, offline
    add_column :agents, :last_activity_at, :timestamp unless column_exists?(:agents, :last_activity_at)
    add_column :agents, :mobile_push_token, :string unless column_exists?(:agents, :mobile_push_token)
  end

  def down
    # Drop tables in reverse order
    drop_table :webhook_events, if_exists: true
    drop_table :push_notifications, if_exists: true
    drop_table :widget_themes, if_exists: true
    drop_table :contact_list_memberships, if_exists: true
    drop_table :contact_lists, if_exists: true
    drop_table :shared_files, if_exists: true
    drop_table :typing_indicators, if_exists: true
    drop_table :conversation_analytics, if_exists: true
    drop_table :email_sequence_executions, if_exists: true
    drop_table :email_sequence_steps, if_exists: true
    drop_table :email_sequences, if_exists: true
    drop_table :proactive_messages, if_exists: true
    drop_table :flow_builders, if_exists: true
    drop_table :chat_ratings, if_exists: true
    drop_table :visitor_sessions, if_exists: true

    # Remove columns from existing tables
    remove_column :agents, :mobile_push_token, if_exists: true
    remove_column :agents, :last_activity_at, if_exists: true
    remove_column :agents, :online_status, if_exists: true
    remove_column :app_users, :lifecycle_stage, if_exists: true
    remove_column :app_users, :lead_score, if_exists: true
    remove_column :app_users, :last_contacted_at, if_exists: true
    remove_column :app_users, :total_conversations, if_exists: true
    remove_column :conversations, :customer_satisfaction_score, if_exists: true
    remove_column :conversations, :resolution_time_seconds, if_exists: true
    remove_column :conversations, :conversation_rating, if_exists: true
    remove_column :apps, :tidio_features, if_exists: true
  end
end