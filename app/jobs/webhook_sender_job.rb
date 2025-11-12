# frozen_string_literal: true

class WebhookSenderJob < ApplicationJob
  queue_as :default

  def perform(webhook_url, payload, headers = {})
    return unless webhook_url.present?

    # Create webhook event record
    webhook_event = WebhookEvent.create!(
      app: extract_app_from_payload(payload),
      event_type: payload[:event_type] || payload['event_type'] || 'custom',
      payload: payload,
      webhook_url: webhook_url,
      attempts: 0,
      delivered: false
    )

    # Deliver webhook
    webhook_event.deliver!
  rescue StandardError => e
    Rails.logger.error "Webhook delivery failed: #{e.message}"
    webhook_event&.update!(error_message: e.message)
    raise
  end

  private

  def extract_app_from_payload(payload)
    app_id = payload[:app_id] || payload['app_id']
    App.find_by(id: app_id) if app_id
  end
end


