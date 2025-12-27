# frozen_string_literal: true

module Mutations
  module FlowBuilders
    class DeleteFlow < Mutations::BaseMutation
      field :success, GraphQL::Types::Boolean, null: false
      field :errors, [String], null: false

      argument :app_key, String, required: true
      argument :flow_id, GraphQL::Types::ID, required: true

      def resolve(app_key:, flow_id:)
        app = find_app(app_key)
        authorize! app, to: :can_manage_bots?, with: AppPolicy, context: { app: app }

        flow_builder = app.flow_builders.find(flow_id)
        flow_builder.destroy!

        {
          success: true,
          errors: []
        }
      rescue StandardError => e
        {
          success: false,
          errors: [e.message]
        }
      end

      private

      def find_app(app_key)
        current_user.apps.find_by(key: app_key) || raise(GraphQL::ExecutionError, "App not found")
      end
    end
  end
end
