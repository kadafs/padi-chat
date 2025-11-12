# frozen_string_literal: true

class ProactiveMessageService < BaseService
  def initialize(app)
    @app = app
  end

  # Create a new proactive message campaign
  def create_campaign(params)
    message = @app.proactive_messages.build(
      name: params[:name],
      trigger_type: params[:trigger_type] || 'time_based',
      delay_seconds: params[:delay_seconds] || 30,
      message_content: format_message_content(params[:message_content]),
      trigger_conditions: params[:trigger_conditions] || {},
      targeting_rules: params[:targeting_rules] || {},
      schedule: params[:schedule] || {},
      priority: params[:priority] || 0,
      start_date: params[:start_date],
      end_date: params[:end_date],
      active: params[:active] != false
    )

    if message.save
      # Schedule activation if needed
      schedule_campaign_activation(message) if message.start_date&.future?
      
      { success: true, message: message }
    else
      { success: false, errors: message.errors }
    end
  end

  # Update existing proactive message
  def update_campaign(message_id, params)
    message = @app.proactive_messages.find(message_id)
    
    old_active_state = message.active
    
    if message.update(
      name: params[:name] || message.name,
      trigger_type: params[:trigger_type] || message.trigger_type,
      delay_seconds: params[:delay_seconds] || message.delay_seconds,
      message_content: params[:message_content] ? format_message_content(params[:message_content]) : message.message_content,
      trigger_conditions: params[:trigger_conditions] || message.trigger_conditions,
      targeting_rules: params[:targeting_rules] || message.targeting_rules,
      schedule: params[:schedule] || message.schedule,
      priority: params[:priority] || message.priority,
      start_date: params[:start_date] || message.start_date,
      end_date: params[:end_date] || message.end_date,
      active: params.key?(:active) ? params[:active] : message.active
    )
      # Handle activation state changes
      handle_activation_change(message, old_active_state) if old_active_state != message.active
      
      { success: true, message: message }
    else
      { success: false, errors: message.errors }
    end
  end

  # Test a proactive message with sample visitor data
  def test_campaign(message_id, sample_visitor_data = nil)
    message = @app.proactive_messages.find(message_id)
    
    # Create a test visitor session
    test_session = build_test_visitor_session(sample_visitor_data)
    
    # Check if message would trigger
    would_trigger = message.should_trigger_for_session?(test_session) && 
                   message.matches_visitor?(test_session)
    
    {
      would_trigger: would_trigger,
      trigger_reason: would_trigger ? analyze_trigger_reason(message, test_session) : nil,
      formatted_message: message.formatted_message,
      test_session: {
        duration_seconds: test_session.duration_seconds,
        page_views: test_session.page_views,
        device_type: test_session.device_type,
        location: test_session.location_string,
        is_returning: test_session.is_returning
      }
    }
  end

  # Get campaign performance analytics
  def get_campaign_analytics(message_id, time_range = '7d')
    message = @app.proactive_messages.find(message_id)
    
    end_time = Time.current
    start_time = case time_range
                 when '1d'
                   1.day.ago
                 when '7d'
                   7.days.ago
                 when '30d'
                   30.days.ago
                 else
                   7.days.ago
                 end

    # This would require additional tracking tables in a real implementation
    # For now, we'll return mock analytics
    {
      impressions: rand(100..1000),
      conversations_started: rand(10..100),
      conversion_rate: rand(5..25),
      average_response_time: rand(30..300),
      top_trigger_pages: generate_mock_trigger_data,
      hourly_performance: generate_mock_hourly_data,
      device_breakdown: {
        desktop: rand(40..60),
        mobile: rand(30..50),
        tablet: rand(5..15)
      }
    }
  end

  # Check all active campaigns for a visitor session
  def check_campaigns_for_session(visitor_session)
    triggered_campaigns = []
    
    @app.proactive_messages
        .active
        .scheduled_now
        .by_priority
        .each do |message|
      
      next unless should_trigger_campaign?(message, visitor_session)
      
      triggered_campaigns << {
        campaign: message,
        trigger_reason: analyze_trigger_reason(message, visitor_session)
      }
      
      # Only trigger the highest priority campaign
      break
    end
    
    triggered_campaigns
  end

  # Execute a proactive message campaign
  def execute_campaign(message, visitor_session)
    return false unless message.active? && message.within_schedule? && message.within_date_range?
    return false unless should_trigger_campaign?(message, visitor_session)

    # Create conversation if needed
    conversation = find_or_create_conversation(visitor_session)
    
    # Send the proactive message
    message_sent = send_proactive_message(conversation, message, visitor_session)
    
    if message_sent
      # Track the campaign execution
      track_campaign_execution(message, visitor_session, conversation)
      
      # Notify via WebSocket
      notify_visitor(visitor_session, message, conversation)
      
      true
    else
      false
    end
  end

  # Get campaign suggestions based on visitor behavior
  def suggest_campaigns(visitor_patterns)
    suggestions = []
    
    # High bounce rate suggestion
    if visitor_patterns[:bounce_rate] > 70
      suggestions << {
        type: 'exit_intent',
        title: 'Reduce Bounce Rate',
        description: 'Create an exit-intent campaign to engage visitors before they leave',
        template: generate_exit_intent_template
      }
    end
    
    # Long time on page suggestion
    if visitor_patterns[:avg_time_on_page] > 120
      suggestions << {
        type: 'engagement',
        title: 'Engage Interested Visitors',
        description: 'Target visitors who spend more than 2 minutes on key pages',
        template: generate_engagement_template
      }
    end
    
    # Cart abandonment suggestion
    if visitor_patterns[:cart_abandonment_rate] > 50
      suggestions << {
        type: 'cart_recovery',
        title: 'Recover Abandoned Carts',
        description: 'Help visitors complete their purchase with timely assistance',
        template: generate_cart_recovery_template
      }
    end
    
    suggestions
  end

  # Pause/Resume campaign
  def toggle_campaign_status(message_id)
    message = @app.proactive_messages.find(message_id)
    message.update!(active: !message.active?)
    
    {
      success: true,
      status: message.active? ? 'active' : 'paused',
      message: message
    }
  end

  # Duplicate a campaign
  def duplicate_campaign(message_id)
    original = @app.proactive_messages.find(message_id)
    
    duplicate = original.dup
    duplicate.name = "#{original.name} (Copy)"
    duplicate.active = false
    
    if duplicate.save
      { success: true, message: duplicate }
    else
      { success: false, errors: duplicate.errors }
    end
  end

  private

  def format_message_content(content)
    {
      text: content[:text] || content[:message] || '',
      avatar: content[:avatar],
      quick_replies: content[:quick_replies] || [],
      attachments: content[:attachments] || [],
      theme: content[:theme] || 'default'
    }
  end

  def schedule_campaign_activation(message)
    # This would use a job scheduler like sidekiq-cron
    CampaignActivationJob.perform_at(message.start_date, message.id)
  end

  def handle_activation_change(message, old_state)
    if !old_state && message.active?
      # Campaign was activated
      Rails.logger.info "Proactive message campaign '#{message.name}' activated"
    elsif old_state && !message.active?
      # Campaign was deactivated
      Rails.logger.info "Proactive message campaign '#{message.name}' deactivated"
    end
  end

  def build_test_visitor_session(data = nil)
    data ||= {
      duration_seconds: 45,
      page_views: 2,
      device_type: 'desktop',
      country_code: 'US',
      current_page: '/products',
      is_returning: false
    }
    
    OpenStruct.new(data.merge(
      location_string: "#{data[:city] || 'New York'}, #{data[:country_code] || 'US'}",
      custom_attributes: data[:custom_attributes] || {}
    ))
  end

  def analyze_trigger_reason(message, visitor_session)
    reasons = []
    
    case message.trigger_type
    when 'time_based'
      conditions = message.trigger_conditions['time_based'] || {}
      min_time = conditions['min_time_seconds'] || message.delay_seconds
      
      if visitor_session.duration_seconds >= min_time
        reasons << "Visitor spent #{visitor_session.duration_seconds}s on site (min: #{min_time}s)"
      end
      
    when 'behavior_based'
      conditions = message.trigger_conditions['behavior_based'] || {}
      
      if conditions['min_pages_viewed'] && visitor_session.page_views >= conditions['min_pages_viewed'].to_i
        reasons << "Visitor viewed #{visitor_session.page_views} pages (min: #{conditions['min_pages_viewed']})"
      end
      
    when 'exit_intent'
      reasons << "Exit intent detected"
      
    end
    
    # Check targeting rules
    rules = message.targeting_rules || {}
    
    if rules['countries']&.include?(visitor_session.country_code)
      reasons << "Visitor from targeted country: #{visitor_session.country_code}"
    end
    
    if rules['devices']&.include?(visitor_session.device_type)
      reasons << "Visitor using targeted device: #{visitor_session.device_type}"
    end
    
    reasons.join(', ')
  end

  def should_trigger_campaign?(message, visitor_session)
    # Check if already sent to this visitor
    return false if already_sent_to_visitor?(message, visitor_session)
    
    # Check basic trigger conditions
    return false unless message.should_trigger_for_session?(visitor_session)
    
    # Check targeting rules
    return false unless message.matches_visitor?(visitor_session)
    
    true
  end

  def already_sent_to_visitor?(message, visitor_session)
    # In a real implementation, this would check a tracking table
    sent_messages = visitor_session.custom_attributes&.dig('sent_proactive_messages') || []
    sent_messages.include?(message.id)
  end

  def find_or_create_conversation(visitor_session)
    existing_conversation = @app.conversations
                               .joins(:main_participant)
                               .where(main_participant: visitor_session.app_user)
                               .opened
                               .last

    if existing_conversation
      existing_conversation
    else
      @app.start_conversation(
        from: visitor_session.app_user,
        participant: visitor_session.app_user,
        subject: 'Proactive Chat',
        message_source: 'proactive'
      )
    end
  end

  def send_proactive_message(conversation, message, visitor_session)
    formatted_message = message.formatted_message
    
    conversation.add_message(
      from: @app.agent_bots.first,
      message: {
        html: formatted_message[:text],
        serialized_content: formatted_message[:text],
        blocks: build_message_blocks(formatted_message)
      },
      message_source: 'proactive',
      controls: build_quick_replies(formatted_message[:quick_replies])
    )
  rescue StandardError => e
    Rails.logger.error "Failed to send proactive message: #{e.message}"
    false
  end

  def build_message_blocks(formatted_message)
    blocks = []
    
    if formatted_message[:text].present?
      blocks << {
        type: 'text',
        data: { text: formatted_message[:text] }
      }
    end
    
    formatted_message[:attachments]&.each do |attachment|
      blocks << {
        type: 'image',
        data: {
          url: attachment[:url],
          caption: attachment[:caption]
        }
      }
    end
    
    blocks
  end

  def build_quick_replies(quick_replies)
    return nil unless quick_replies&.any?
    
    {
      type: 'data_retrieval',
      schema: quick_replies.map do |reply|
        {
          type: 'button',
          text: reply[:text],
          value: reply[:value] || reply[:text]
        }
      end
    }
  end

  def track_campaign_execution(message, visitor_session, conversation)
    # In a real implementation, this would create tracking records
    Rails.logger.info "Proactive message '#{message.name}' executed for visitor #{visitor_session.session_id}"
    
    # Update visitor session to track sent message
    sent_messages = visitor_session.custom_attributes['sent_proactive_messages'] || []
    sent_messages << message.id
    
    visitor_session.update!(
      custom_attributes: visitor_session.custom_attributes.merge(
        'sent_proactive_messages' => sent_messages,
        'last_proactive_message' => {
          message_id: message.id,
          sent_at: Time.current.to_i,
          conversation_id: conversation.id
        }
      )
    )
  end

  def notify_visitor(visitor_session, message, conversation)
    broadcast_key = "#{@app.key}-#{visitor_session.session_id}"
    
    MessengerEventsChannel.broadcast_to(
      broadcast_key,
      {
        type: 'proactive_message',
        data: {
          conversation_id: conversation.key,
          message: message.formatted_message,
          campaign_id: message.id,
          campaign_name: message.name
        }
      }
    )
  end

  def generate_mock_trigger_data
    [
      { page: '/products', triggers: rand(20..50) },
      { page: '/pricing', triggers: rand(15..30) },
      { page: '/checkout', triggers: rand(10..25) },
      { page: '/support', triggers: rand(5..15) }
    ]
  end

  def generate_mock_hourly_data
    24.times.map do |hour|
      {
        hour: hour,
        triggers: rand(0..10),
        conversations: rand(0..5)
      }
    end
  end

  def generate_exit_intent_template
    {
      name: 'Exit Intent - Don\'t Leave Yet!',
      trigger_type: 'exit_intent',
      message_content: {
        text: 'Wait! Before you go, is there anything I can help you with?',
        quick_replies: [
          { text: 'I have a question', value: 'question' },
          { text: 'Just browsing', value: 'browsing' },
          { text: 'Looking for deals', value: 'deals' }
        ]
      },
      targeting_rules: {
        new_only: true
      }
    }
  end

  def generate_engagement_template
    {
      name: 'Engaged Visitor Assistance',
      trigger_type: 'time_based',
      delay_seconds: 120,
      message_content: {
        text: 'I see you\'ve been exploring our site! Can I help you find what you\'re looking for?',
        quick_replies: [
          { text: 'Yes, I need help', value: 'help' },
          { text: 'Just looking around', value: 'browsing' }
        ]
      },
      trigger_conditions: {
        time_based: {
          min_time_seconds: 120
        }
      }
    }
  end

  def generate_cart_recovery_template
    {
      name: 'Cart Abandonment Recovery',
      trigger_type: 'behavior_based',
      message_content: {
        text: 'I noticed you have items in your cart. Need help completing your order?',
        quick_replies: [
          { text: 'Yes, I have questions', value: 'help' },
          { text: 'I need a discount', value: 'discount' },
          { text: 'Technical issue', value: 'technical' }
        ]
      },
      trigger_conditions: {
        behavior_based: {
          visited_pages: ['/checkout', '/cart']
        }
      }
    }
  end
end