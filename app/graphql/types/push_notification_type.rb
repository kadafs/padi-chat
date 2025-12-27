# frozen_string_literal: true

module Types
  class PushNotificationType < Types::BaseObject
    field :id, GraphQL::Types::ID, null: false
    field :app, Types::AppType, null: false
    field :agent, Types::AgentType, null: true
    field :title, String, null: false
    field :body, String, null: true
    field :notification_type, String, null: true
    field :payload, GraphQL::Types::JSON, null: true
    field :device_tokens, [String], null: false
    field :sent, GraphQL::Types::Boolean, null: false, default_value: false
    field :sent_at, GraphQL::Types::ISO8601DateTime, null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

    field :is_sent, GraphQL::Types::Boolean, null: false
    field :is_pending, GraphQL::Types::Boolean, null: false

    def is_sent
      object.sent?
    end

    def is_pending
      !object.sent?
    end
  end
end



