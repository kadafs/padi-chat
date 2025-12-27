# frozen_string_literal: true

module Types
  class ChatRatingType < Types::BaseObject
    field :id, GraphQL::Types::ID, null: false
    field :conversation, Types::ConversationType, null: false
    field :app_user, Types::AppUserType, null: false
    field :agent, Types::AgentType, null: true
    field :rating, Integer, null: false
    field :feedback, String, null: true
    field :rating_type, String, null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

    field :positive, GraphQL::Types::Boolean, null: false
    field :negative, GraphQL::Types::Boolean, null: false

    def positive
      object.positive?
    end

    def negative
      object.negative?
    end
  end
end


