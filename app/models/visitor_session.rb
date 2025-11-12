# frozen_string_literal: true

class VisitorSession < ApplicationRecord
  belongs_to :app
  belongs_to :app_user
  
  validates :session_id, presence: true, uniqueness: { scope: :app_id }
  validates :device_type, inclusion: { in: %w[desktop tablet mobile] }
  
  scope :active, -> { where('last_activity_at > ?', 5.minutes.ago) }
  scope :returning, -> { where(is_returning: true) }
  scope :by_country, ->(country) { where(country_code: country) }
  scope :by_device, ->(device) { where(device_type: device) }
  
  before_create :set_first_seen_at
  before_save :update_returning_status
  
  # Tidio-like visitor tracking methods
  def duration_seconds
    return 0 unless first_seen_at && last_activity_at
    (last_activity_at - first_seen_at).to_i
  end
  
  def duration_formatted
    return "0s" if duration_seconds <= 0
    
    hours = duration_seconds / 3600
    minutes = (duration_seconds % 3600) / 60
    seconds = duration_seconds % 60
    
    if hours > 0
      "#{hours}h #{minutes}m"
    elsif minutes > 0
      "#{minutes}m #{seconds}s"
    else
      "#{seconds}s"
    end
  end
  
  def is_active?
    last_activity_at && last_activity_at > 5.minutes.ago
  end
  
  def update_activity!
    update!(
      last_activity_at: Time.current,
      time_on_site: duration_seconds
    )
  end
  
  def increment_page_view!(page_url)
    increment!(:page_views)
    update!(
      current_page: page_url,
      last_activity_at: Time.current
    )
  end
  
  def location_string
    [city, country_code].compact.join(', ')
  end

  def broadcast_key
    "#{app.key}-#{session_id}"
  end

  # Check if visitor matches proactive message criteria
  def matches_proactive_criteria?(criteria)
    return false unless criteria.is_a?(Hash)
    
    criteria.all? do |key, value|
      case key.to_s
      when 'min_time_on_site'
        duration_seconds >= value.to_i
      when 'min_pages_viewed'
        page_views >= value.to_i
      when 'device_type'
        device_type == value
      when 'country_codes'
        Array(value).include?(country_code)
      when 'is_returning'
        is_returning == value
      when 'referrer_contains'
        referrer_url&.include?(value)
      else
        custom_attributes[key] == value
      end
    end
  end
  
  private
  
  def set_first_seen_at
    self.first_seen_at ||= Time.current
    self.last_activity_at ||= Time.current
  end
  
  def update_returning_status
    if app_user&.created_at && app_user.created_at < 1.day.ago
      self.is_returning = true
    end
  end
end