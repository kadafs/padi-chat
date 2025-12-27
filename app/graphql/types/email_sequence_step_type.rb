# frozen_string_literal: true

module Types
  class EmailSequenceStepType < Types::BaseObject
    field :id, GraphQL::Types::ID, null: false
    field :email_sequence, Types::EmailSequenceType, null: false
    field :name, String, null: false
    field :subject_line, String, null: false
    field :content, String, null: false
    field :step_order, Integer, null: false
    field :delay_days, Integer, null: false, default_value: 0
    field :delay_hours, Integer, null: false, default_value: 0
    field :active, GraphQL::Types::Boolean, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

    field :delay_formatted, String, null: false

    def delay_formatted
      days = object.delay_days || 0
      hours = object.delay_hours || 0

      parts = []
      parts << "#{days} day#{'s' if days != 1}" if days > 0
      parts << "#{hours} hour#{'s' if hours != 1}" if hours > 0

      parts.empty? ? 'Immediate' : parts.join(', ')
    end
  end
end



