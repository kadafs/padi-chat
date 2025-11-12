# frozen_string_literal: true

class WebhookEvent < ApplicationRecord
  belongs_to :app

  validates :event_type, presence: true

  scope :delivered, -> { where(delivered: true) }
  scope :pending, -> { where(delivered: false) }
  scope :failed, -> { where('attempts > 0 AND delivered = false') }
  scope :by_type, ->(type) { where(event_type: type) }

  MAX_ATTEMPTS = 3

  # Tidio-like webhook delivery
  def deliver!
    return if delivered?
    return if attempts >= MAX_ATTEMPTS

    increment!(:attempts)

    begin
      response = send_webhook_request

      if response.success?
        update!(
          delivered: true,
          delivered_at: Time.current,
          error_message: nil
        )
      else
        update!(
          error_message: "HTTP #{response.code}: #{response.body}"
        )
      end
    rescue StandardError => e
      update!(
        error_message: e.message
      )
      raise
    end
  end

  def retry!
    return if delivered?
    return if attempts >= MAX_ATTEMPTS

    deliver!
  end

  private

  def send_webhook_request
    uri = URI(webhook_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    http.read_timeout = 10

    request = Net::HTTP::Post.new(uri.path)
    request['Content-Type'] = 'application/json'
    request['User-Agent'] = 'Chaskiq-Webhook/1.0'
    request.body = payload.to_json

    http.request(request)
  end
end


