# frozen_string_literal: true

module Mutations
  module EmailSequences
    class DuplicateSequence < Mutations::BaseMutation
      field :email_sequence, Types::EmailSequenceType, null: true
      field :errors, [String], null: false

      argument :app_key, String, required: true
      argument :id, GraphQL::Types::ID, required: true

      def resolve(app_key:, id:)
        app = find_app(app_key)
        authorize! app, to: :can_manage_campaigns?, with: AppPolicy, context: { app: app }

        sequence = app.email_sequences.find_by(id: id)
        raise GraphQL::ExecutionError, "Email sequence not found" unless sequence

        duplicated = sequence.duplicate!

        {
          email_sequence: duplicated,
          errors: []
        }
      end

      private

      def find_app(app_key)
        current_user.apps.find_by(key: app_key) || raise(GraphQL::ExecutionError, "App not found")
      end
    end
  end
end
