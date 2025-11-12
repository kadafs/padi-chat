# frozen_string_literal: true

module Types
  class EmailSequenceExecutionType < Types::BaseObject
    field :id, ID, null: false
    field :email_sequence, Types::EmailSequenceType, null: false
    field :app_user, Types::AppUserType, null: false
    field :status, String, null: false
    field :context, GraphQL::Types::JSON, null: true
    field :started_at, GraphQL::Types::ISO8601DateTime, null: true
    field :completed_at, GraphQL::Types::ISO8601DateTime, null: true
    field :error_message, String, null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

    field :is_active, Boolean, null: false
    field :is_completed, Boolean, null: false
    field :is_failed, Boolean, null: false

    def is_active
      %w[started in_progress].include?(object.status)
    end

    def is_completed
      object.status == 'completed'
    end

    def is_failed
      object.status == 'failed'
    end
  end
end


