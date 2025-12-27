# frozen_string_literal: true

module Mutations
  module ProactiveMessages
    class InitiateProactiveChat < Mutations::BaseMutation
      field :conversation, Types::ConversationType, null: true
      field :errors, [String], null: false

      argument :app_key, String, required: true
      argument :session_id, String, required: true
      argument :message_template, GraphQL::Types::JSON, required: true

      def resolve(app_key:, session_id:, message_template:)
        app = find_app(app_key)
        authorize! app, to: :can_manage_proactive_messages?, with: AppPolicy, context: { app: app }

        service = ProactiveMessageService.new(app)
        conversation = service.initiate_proactive_chat(session_id, message_template)

        if conversation
          {
            conversation: conversation,
            errors: []
          }
        else
          {
            conversation: nil,
            errors: ["Failed to initiate proactive chat"]
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
