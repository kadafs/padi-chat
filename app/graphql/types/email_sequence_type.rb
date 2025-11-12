# frozen_string_literal: true

module Types
  class EmailSequenceType < Types::BaseObject
    field :id, ID, null: false
    field :app, Types::AppType, null: false
    field :name, String, null: false
    field :description, String, null: true
    field :trigger_event, String, null: true
    field :active, Boolean, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

    field :steps, [Types::EmailSequenceStepType], null: false
    field :executions, [Types::EmailSequenceExecutionType], null: false
    field :steps_count, Integer, null: false
    field :active_executions_count, Integer, null: false

    def steps
      object.email_sequence_steps.ordered
    end

    def executions
      object.email_sequence_executions.order(created_at: :desc).limit(100)
    end

    def steps_count
      object.email_sequence_steps.count
    end

    def active_executions_count
      object.email_sequence_executions.active.count
    end
  end
end


