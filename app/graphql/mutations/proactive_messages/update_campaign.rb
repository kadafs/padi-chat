# frozen_string_literal: true

module Mutations
  module ProactiveMessages
    class UpdateCampaign < Mutations::BaseMutation
      field :proactive_message, Types::ProactiveMessageType, null: true
      field :errors, [String], null: false

      argument :app_key, String, required: true
      argument :campaign_id, GraphQL::Types::ID, required: true
      argument :campaign_data, Types::ProactiveMessageInputType, required: true

      def resolve(app_key:, campaign_id:, campaign_data:)
        app = find_app(app_key)
        authorize! app, to: :can_manage_proactive_messages?, with: AppPolicy, context: { app: app }

        service = ProactiveMessageService.new(app)
        result = service.update_campaign(campaign_id, campaign_data.to_h)

        if result[:success]
          {
            proactive_message: result[:message],
            errors: []
          }
        else
          {
            proactive_message: nil,
            errors: result[:errors].is_a?(ActiveModel::Errors) ? result[:errors].full_messages : [result[:errors].to_s]
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
