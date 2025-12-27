# frozen_string_literal: true

module Types
  class TypingIndicatorType < Types::BaseObject
    field :id, GraphQL::Types::ID, null: false
    field :conversation, Types::ConversationType, null: false
    field :user, Types::AuthorType, null: false
    field :is_typing, GraphQL::Types::Boolean, null: false
    field :started_typing_at, GraphQL::Types::ISO8601DateTime, null: true
    field :stopped_typing_at, GraphQL::Types::ISO8601DateTime, null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

    field :typing_duration_seconds, Integer, null: true

    def typing_duration_seconds
      return nil unless object.started_typing_at

      end_time = object.stopped_typing_at || Time.current
      (end_time - object.started_typing_at).to_i
    end
  end
end



