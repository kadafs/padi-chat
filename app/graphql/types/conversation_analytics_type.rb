# frozen_string_literal: true

module Types
  class ConversationAnalyticsType < Types::BaseObject
    field :id, ID, null: false
    field :conversation, Types::ConversationType, null: false
    field :first_response_time_seconds, Integer, null: true
    field :resolution_time_seconds, Integer, null: true
    field :agent_messages_count, Integer, null: false, default_value: 0
    field :customer_messages_count, Integer, null: false, default_value: 0
    field :bot_messages_count, Integer, null: false, default_value: 0
    field :escalated_to_human, Boolean, null: false, default_value: false
    field :first_response_at, GraphQL::Types::ISO8601DateTime, null: true
    field :resolution_at, GraphQL::Types::ISO8601DateTime, null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

    field :first_response_time_formatted, String, null: true
    field :resolution_time_formatted, String, null: true
    field :total_messages_count, Integer, null: false

    def first_response_time_formatted
      object.first_response_time_formatted
    end

    def resolution_time_formatted
      object.resolution_time_formatted
    end

    def total_messages_count
      (object.agent_messages_count || 0) + 
      (object.customer_messages_count || 0) + 
      (object.bot_messages_count || 0)
    end
  end
end


