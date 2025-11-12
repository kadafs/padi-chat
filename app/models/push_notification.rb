# frozen_string_literal: true

class PushNotification < ApplicationRecord
  belongs_to :app
  belongs_to :agent, optional: true

  validates :title, presence: true

  scope :sent, -> { where(sent: true) }
  scope :pending, -> { where(sent: false) }
  scope :by_type, ->(type) { where(notification_type: type) }

  # Tidio-like push notification sending
  def send!
    return if sent?

    # Send to all device tokens
    device_tokens.each do |token|
      send_to_device(token)
    end

    update!(
      sent: true,
      sent_at: Time.current
    )
  end

  def send_to_device(device_token)
    # This would integrate with FCM, APNs, or other push services
    # For now, we'll just log it
    Rails.logger.info "Sending push notification to #{device_token}: #{title}"
    
    # In production, you'd use something like:
    # FCM.send(device_token, {
    #   title: title,
    #   body: body,
    #   data: payload
    # })
  end
end


