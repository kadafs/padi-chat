# frozen_string_literal: true

module Types
  class WebhookEventType < Types::BaseObject
    field :id, GraphQL::Types::ID, null: false
    field :app, Types::AppType, null: false
    field :event_type, String, null: false
    field :webhook_url, String, null: false
    field :payload, GraphQL::Types::JSON, null: true
    field :delivered, GraphQL::Types::Boolean, null: false, default_value: false
    field :delivered_at, GraphQL::Types::ISO8601DateTime, null: true
    field :attempts, Integer, null: false, default_value: 0
    field :error_message, String, null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

    field :is_delivered, GraphQL::Types::Boolean, null: false
    field :is_pending, GraphQL::Types::Boolean, null: false
    field :is_failed, GraphQL::Types::Boolean, null: false
    field :can_retry, GraphQL::Types::Boolean, null: false

    def is_delivered
      object.delivered?
    end

    def is_pending
      !object.delivered? && object.attempts == 0
    end

    def is_failed
      !object.delivered? && object.attempts > 0
    end

    def can_retry
      !object.delivered? && object.attempts < 3
    end
  end
end



