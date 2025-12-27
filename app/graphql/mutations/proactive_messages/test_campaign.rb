# frozen_string_literal: true

module Mutations
  module ProactiveMessages
    class TestCampaign < Mutations::BaseMutation
      field :test_result, GraphQL::Types::JSON, null: true
      field :errors, [String], null: false

      argument :app_key, String, required: true
      argument :campaign_id, GraphQL::Types::ID, required: true
      argument :sample_visitor_data, GraphQL::Types::JSON, required: false

      def resolve(app_key:, campaign_id:, sample_visitor_data: nil)
        app = find_app(app_key)
        authorize! app, to: :can_manage_proactive_messages?, with: AppPolicy, context: { app: app }

        service = ProactiveMessageService.new(app)
        result = service.test_campaign(campaign_id, sample_visitor_data)

        {
          test_result: result,
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
