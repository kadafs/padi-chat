# frozen_string_literal: true

class ProactiveMessage < ApplicationRecord
  belongs_to :app
  
  validates :name, presence: true
  validates :delay_seconds, presence: true, numericality: { greater_than: 0 }
  validates :trigger_type, inclusion: { 
    in: %w[time_based behavior_based exit_intent scroll_based page_based] 
  }
  
  scope :active, -> { where(active: true) }
  scope :by_trigger_type, ->(type) { where(trigger_type: type) }
  scope :by_priority, -> { order(priority: :desc) }
  scope :scheduled_now, -> { 
    where(
      '(start_date IS NULL OR start_date <= ?) AND (end_date IS NULL OR end_date >= ?)',
      Time.current, Time.current
    )
  }
  
  before_validation :set_defaults
  
  # Tidio-like proactive messaging logic
  def should_trigger_for_session?(visitor_session)
    return false unless active? && within_schedule? && within_date_range?
    
    # Check basic conditions
    return false unless visitor_session.duration_seconds >= delay_seconds
    
    # Check trigger conditions
    case trigger_type
    when 'time_based'
      check_time_based_conditions(visitor_session)
    when 'behavior_based'
      check_behavior_conditions(visitor_session)
    when 'exit_intent'
      check_exit_intent_conditions(visitor_session)
    when 'scroll_based'
      check_scroll_conditions(visitor_session)
    when 'page_based'
      check_page_conditions(visitor_session)
    else
      false
    end
  end
  
  def formatted_message
    return {} unless message_content.present?
    
    {
      text: message_content['text'] || 'Hello! How can I help you today?',
      avatar: message_content['avatar'],
      quick_replies: message_content['quick_replies'] || [],
      attachments: message_content['attachments'] || []
    }
  end
  
  def targeting_summary
    rules = targeting_rules || {}
    summary = []
    
    summary << "#{rules['countries']&.join(', ')}" if rules['countries']&.any?
    summary << "#{rules['devices']&.join(', ')} devices" if rules['devices']&.any?
    summary << "Returning visitors only" if rules['returning_only']
    summary << "New visitors only" if rules['new_only']
    
    summary.any? ? summary.join(' • ') : 'All visitors'
  end
  
  def matches_visitor?(visitor_session)
    rules = targeting_rules || {}
    
    # Country targeting
    if rules['countries']&.any?
      return false unless rules['countries'].include?(visitor_session.country_code)
    end
    
    # Device targeting
    if rules['devices']&.any?
      return false unless rules['devices'].include?(visitor_session.device_type)
    end
    
    # Visitor type targeting
    if rules['returning_only'] && !visitor_session.is_returning
      return false
    end
    
    if rules['new_only'] && visitor_session.is_returning
      return false
    end
    
    # URL targeting
    if rules['url_contains']
      return false unless visitor_session.current_page&.include?(rules['url_contains'])
    end
    
    if rules['referrer_contains']
      return false unless visitor_session.referrer_url&.include?(rules['referrer_contains'])
    end
    
    # Custom attributes
    if rules['custom_attributes']&.any?
      rules['custom_attributes'].each do |key, value|
        return false unless visitor_session.custom_attributes[key] == value
      end
    end
    
    true
  end
  
  def within_schedule?
    return true unless schedule&.any?
    
    now = Time.current.in_time_zone(app.timezone || 'UTC')
    current_day = now.strftime('%A').downcase
    current_hour = now.hour
    
    day_schedule = schedule[current_day]
    return false unless day_schedule
    
    return false unless day_schedule['enabled']
    
    start_hour = day_schedule['start_hour'] || 0
    end_hour = day_schedule['end_hour'] || 23
    
    current_hour >= start_hour && current_hour <= end_hour
  end
  
  def within_date_range?
    now = Time.current
    
    if start_date && now < start_date
      return false
    end
    
    if end_date && now > end_date
      return false
    end
    
    true
  end
  
  private
  
  def set_defaults
    self.trigger_conditions ||= {}
    self.message_content ||= {}
    self.targeting_rules ||= {}
    self.schedule ||= {}
  end
  
  def check_time_based_conditions(visitor_session)
    conditions = trigger_conditions['time_based'] || {}
    
    min_time = conditions['min_time_seconds'] || delay_seconds
    visitor_session.duration_seconds >= min_time
  end
  
  def check_behavior_conditions(visitor_session)
    conditions = trigger_conditions['behavior_based'] || {}
    
    # Check minimum pages viewed
    if conditions['min_pages_viewed']
      return false if visitor_session.page_views < conditions['min_pages_viewed'].to_i
    end
    
    # Check if specific pages were visited
    if conditions['visited_pages']&.any?
      # This would need to be tracked separately with page visit history
      # For now, return true if current page matches
      return conditions['visited_pages'].any? { |page| 
        visitor_session.current_page&.include?(page) 
      }
    end
    
    true
  end
  
  def check_exit_intent_conditions(visitor_session)
    # Exit intent would be detected via JavaScript and sent to backend
    # For now, return true if visitor has been idle
    visitor_session.last_activity_at < 30.seconds.ago
  end
  
  def check_scroll_conditions(visitor_session)
    conditions = trigger_conditions['scroll_based'] || {}
    scroll_percentage = conditions['scroll_percentage'] || 50
    
    # This would need to be tracked via JavaScript
    # For now, assume scrolling is related to time on page
    visitor_session.duration_seconds >= 30
  end
  
  def check_page_conditions(visitor_session)
    conditions = trigger_conditions['page_based'] || {}
    
    if conditions['specific_pages']&.any?
      return conditions['specific_pages'].any? { |page| 
        visitor_session.current_page&.include?(page) 
      }
    end
    
    true
  end
end