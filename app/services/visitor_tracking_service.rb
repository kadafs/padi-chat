# frozen_string_literal: true

class VisitorTrackingService < BaseService
  def initialize(app)
    @app = app
  end

  # Track a new visitor session
  def track_visitor(params)
    session_id = params[:session_id] || generate_session_id
    app_user = find_or_create_app_user(params)
    
    visitor_session = find_or_create_visitor_session(session_id, app_user, params)
    update_visitor_session(visitor_session, params)
    
    # Check for proactive message triggers
    check_proactive_triggers(visitor_session)
    
    visitor_session
  end

  # Update visitor activity
  def update_activity(session_id, params)
    visitor_session = @app.visitor_sessions.find_by(session_id: session_id)
    return nil unless visitor_session

    visitor_session.update_activity!
    
    # Update current page if provided
    if params[:current_page]
      visitor_session.increment_page_view!(params[:current_page])
    end

    # Update custom attributes
    if params[:custom_attributes]
      visitor_session.custom_attributes.merge!(params[:custom_attributes])
      visitor_session.save!
    end

    # Check for proactive triggers on page change
    check_proactive_triggers(visitor_session) if params[:current_page]

    visitor_session
  end

  # Get visitor analytics
  def get_analytics(time_range = '24h')
    end_time = Time.current
    start_time = case time_range
                 when '1h'
                   1.hour.ago
                 when '24h'
                   24.hours.ago
                 when '7d'
                   7.days.ago
                 when '30d'
                   30.days.ago
                 else
                   24.hours.ago
                 end

    sessions = @app.visitor_sessions.where(created_at: start_time..end_time)

    {
      total_visitors: sessions.count,
      online_visitors: sessions.active.count,
      unique_visitors: sessions.distinct.count(:app_user_id),
      returning_visitors: sessions.returning.count,
      average_time_on_site: sessions.average(:time_on_site)&.to_i || 0,
      total_page_views: sessions.sum(:page_views),
      device_breakdown: device_breakdown(sessions),
      location_breakdown: location_breakdown(sessions),
      traffic_sources: traffic_sources(sessions),
      hourly_activity: hourly_activity(sessions),
      popular_pages: popular_pages(sessions)
    }
  end

  # Get live visitors
  def get_live_visitors(limit = 50)
    @app.visitor_sessions
        .includes(:app_user)
        .active
        .order(last_activity_at: :desc)
        .limit(limit)
        .map { |session| format_visitor_data(session) }
  end

  # Initiate proactive chat
  def initiate_proactive_chat(session_id, message_template)
    visitor_session = @app.visitor_sessions.find_by(session_id: session_id)
    return nil unless visitor_session

    # Create or find existing conversation
    conversation = find_or_create_conversation(visitor_session)
    
    # Send proactive message
    if message_template && message_template['content']
      conversation.add_message(
        from: @app.agent_bots.first,
        message: {
          html: message_template['content'],
          serialized_content: message_template['content']
        },
        message_source: 'proactive'
      )
    end

    # Notify visitor via WebSocket
    MessengerEventsChannel.broadcast_to(
      visitor_session.broadcast_key,
      {
        type: 'proactive_message',
        data: {
          conversation_id: conversation.key,
          message: message_template
        }
      }
    )

    conversation
  end

  # Track custom events
  def track_event(session_id, event_name, event_data = {})
    visitor_session = @app.visitor_sessions.find_by(session_id: session_id)
    return nil unless visitor_session

    # Store event in custom attributes
    events = visitor_session.custom_attributes['events'] || []
    events << {
      name: event_name,
      data: event_data,
      timestamp: Time.current.to_i
    }

    # Keep only last 50 events
    events = events.last(50)
    
    visitor_session.update!(
      custom_attributes: visitor_session.custom_attributes.merge('events' => events)
    )

    # Check for flow triggers based on custom events
    check_flow_triggers(visitor_session, event_name, event_data)

    true
  end

  # Get visitor journey/path
  def get_visitor_journey(session_id)
    visitor_session = @app.visitor_sessions.find_by(session_id: session_id)
    return [] unless visitor_session

    events = visitor_session.custom_attributes['page_views'] || []
    events.map do |page_view|
      {
        page: page_view['url'],
        title: page_view['title'],
        timestamp: Time.at(page_view['timestamp']),
        duration: page_view['duration'] || 0
      }
    end
  end

  # Generate visitor score/lead score
  def calculate_visitor_score(visitor_session)
    score = 0
    
    # Time on site (max 30 points)
    time_score = [visitor_session.duration_seconds / 60, 30].min
    score += time_score

    # Page views (5 points per page, max 25 points)
    page_score = [visitor_session.page_views * 5, 25].min
    score += page_score

    # Returning visitor (10 points)
    score += 10 if visitor_session.is_returning

    # High-value pages (20 points)
    if visitor_session.current_page&.include?('/pricing') || 
       visitor_session.current_page&.include?('/checkout')
      score += 20
    end

    # Email provided (15 points)
    score += 15 if visitor_session.app_user.email.present?

    # Custom attributes scoring
    custom_attrs = visitor_session.custom_attributes || {}
    
    # Cart value scoring
    if custom_attrs['cart_value']
      cart_value = custom_attrs['cart_value'].to_f
      score += (cart_value / 50).round # 1 point per $50
    end

    # Engagement events
    events = custom_attrs['events'] || []
    score += events.count { |e| ['video_watched', 'download', 'form_started'].include?(e['name']) } * 5

    [score, 100].min # Cap at 100
  end

  private

  def generate_session_id
    "sess_#{SecureRandom.hex(16)}"
  end

  def find_or_create_app_user(params)
    # Try to find existing user by email or session ID
    if params[:email].present?
      user = @app.app_users.find_by(email: params[:email])
      return user if user
    end

    if params[:user_id].present?
      user = @app.app_users.find_by(id: params[:user_id])
      return user if user
    end

    # Create new visitor
    @app.app_users.create!(
      email: params[:email],
      first_name: params[:first_name],
      last_name: params[:last_name],
      session_id: params[:session_id],
      properties: params[:custom_attributes] || {},
      type: 'Visitor'
    )
  end

  def find_or_create_visitor_session(session_id, app_user, params)
    session = @app.visitor_sessions.find_by(session_id: session_id)
    
    if session
      session
    else
      @app.visitor_sessions.create!(
        session_id: session_id,
        app_user: app_user,
        referrer_url: params[:referrer],
        landing_page: params[:landing_page] || params[:current_page],
        current_page: params[:current_page],
        utm_parameters: extract_utm_parameters(params),
        device_type: detect_device_type(params[:user_agent]),
        browser: detect_browser(params[:user_agent]),
        os: detect_os(params[:user_agent]),
        country_code: params[:country_code],
        city: params[:city],
        ip_address: params[:ip_address],
        geolocation: params[:geolocation] || {},
        custom_attributes: params[:custom_attributes] || {}
      )
    end
  end

  def update_visitor_session(visitor_session, params)
    updates = {}
    
    updates[:current_page] = params[:current_page] if params[:current_page]
    updates[:last_activity_at] = Time.current
    
    if params[:custom_attributes]
      updates[:custom_attributes] = visitor_session.custom_attributes.merge(params[:custom_attributes])
    end

    visitor_session.update!(updates) if updates.any?
  end

  def check_proactive_triggers(visitor_session)
    @app.proactive_messages.active
                   .scheduled_now
                   .by_priority
                   .find_each do |message|
      next unless message.should_trigger_for_session?(visitor_session)
      next unless message.matches_visitor?(visitor_session)

      # Check if we haven't already sent this message to this visitor
      next if already_sent_proactive_message?(visitor_session, message)

      # Trigger the proactive message
      initiate_proactive_chat(
        visitor_session.session_id,
        message.formatted_message
      )

      # Track that we sent this message
      track_proactive_message_sent(visitor_session, message)

      break # Only send one proactive message at a time
    end
  end

  def check_flow_triggers(visitor_session, event_name, event_data)
    FlowBuilder.active.find_each do |flow|
      triggers = flow.triggers || {}
      
      if triggers['custom_event']
        conditions = triggers['custom_event']
        if conditions['event_name'] == event_name
          # Execute the flow
          FlowExecutionJob.perform_later(flow.id, visitor_session.id, {
            event_name: event_name,
            event_data: event_data
          })
        end
      end
    end
  end

  def already_sent_proactive_message?(visitor_session, message)
    sent_messages = visitor_session.custom_attributes['sent_proactive_messages'] || []
    sent_messages.include?(message.id)
  end

  def track_proactive_message_sent(visitor_session, message)
    sent_messages = visitor_session.custom_attributes['sent_proactive_messages'] || []
    sent_messages << message.id
    
    visitor_session.update!(
      custom_attributes: visitor_session.custom_attributes.merge(
        'sent_proactive_messages' => sent_messages
      )
    )
  end

  def find_or_create_conversation(visitor_session)
    # Check for existing open conversation
    conversation = @app.conversations
                      .where(main_participant: visitor_session.app_user)
                      .opened
                      .last

    if conversation
      conversation
    else
      @app.start_conversation(
        from: visitor_session.app_user,
        participant: visitor_session.app_user,
        subject: 'Website Chat',
        message_source: 'website'
      )
    end
  end

  def extract_utm_parameters(params)
    utm_params = {}
    
    %w[utm_source utm_medium utm_campaign utm_term utm_content].each do |param|
      utm_params[param] = params[param.to_sym] if params[param.to_sym].present?
    end
    
    utm_params
  end

  def detect_device_type(user_agent)
    return 'desktop' unless user_agent

    case user_agent.downcase
    when /mobile|android|iphone|ipod|blackberry|windows phone/
      'mobile'
    when /tablet|ipad/
      'tablet'
    else
      'desktop'
    end
  end

  def detect_browser(user_agent)
    return 'unknown' unless user_agent

    case user_agent.downcase
    when /chrome/
      'Chrome'
    when /firefox/
      'Firefox'
    when /safari/
      'Safari'
    when /edge/
      'Edge'
    when /opera/
      'Opera'
    else
      'Other'
    end
  end

  def detect_os(user_agent)
    return 'unknown' unless user_agent

    case user_agent.downcase
    when /windows/
      'Windows'
    when /macintosh|mac os x/
      'macOS'
    when /linux/
      'Linux'
    when /android/
      'Android'
    when /iphone|ipad|ipod/
      'iOS'
    else
      'Other'
    end
  end

  def device_breakdown(sessions)
    sessions.group(:device_type).count
  end

  def location_breakdown(sessions)
    sessions.joins(:app_user)
           .group(:country_code)
           .count
           .map { |country, count| { country: country, visitors: count } }
  end

  def traffic_sources(sessions)
    sessions.group("utm_parameters->>'utm_source'").count
  end

  def hourly_activity(sessions)
    sessions.group_by_hour(:created_at).count
  end

  def popular_pages(sessions)
    sessions.group(:current_page)
           .count
           .sort_by { |_, count| -count }
           .first(10)
           .map { |page, count| { page: page, views: count } }
  end

  def format_visitor_data(session)
    {
      id: session.id,
      session_id: session.session_id,
      name: session.app_user.display_name,
      email: session.app_user.email,
      avatar: session.app_user.avatar_url,
      location: session.location_string,
      country: session.country_code,
      city: session.city,
      device: session.device_type,
      browser: session.browser,
      os: session.os,
      current_page: session.current_page,
      time_on_site: session.duration_formatted,
      page_views: session.page_views,
      visit_count: session.app_user.visits.count,
      is_returning: session.is_returning,
      is_online: session.is_active?,
      referrer: session.referrer_url,
      utm_source: session.utm_parameters['utm_source'],
      utm_medium: session.utm_parameters['utm_medium'],
      first_seen_at: session.first_seen_at,
      last_activity_at: session.last_activity_at,
      lead_score: calculate_visitor_score(session),
      custom_attributes: session.custom_attributes
    }
  end
end