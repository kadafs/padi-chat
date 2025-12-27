# frozen_string_literal: true

module Mutations
  module EmailSequences
    class UpdateSequence < Mutations::BaseMutation
      field :email_sequence, Types::EmailSequenceType, null: true
      field :errors, [String], null: false

      argument :app_key, String, required: true
      argument :id, GraphQL::Types::ID, required: true
      argument :sequence_data, GraphQL::Types::JSON, required: true

      def resolve(app_key:, id:, sequence_data:)
        app = find_app(app_key)
        authorize! app, to: :can_manage_campaigns?, with: AppPolicy, context: { app: app }

        sequence = app.email_sequences.find_by(id: id)
        raise GraphQL::ExecutionError, "Email sequence not found" unless sequence

        if sequence.update(sequence_data.to_h)
          {
            email_sequence: sequence,
            errors: []
          }
        else
          {
            email_sequence: nil,
            errors: sequence.errors.full_messages
          }
        end
      end

      private

      def find_app(app_key)
        current_user.apps.find_by(key: app_key) || raise(GraphQL::ExecutionError, "App not found")
      end
    end
  end
end
