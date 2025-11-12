# frozen_string_literal: true

module Mutations
  module ProactiveMessages
    class CreateCampaign < Mutations::BaseMutation
      field :proactive_message, Types::ProactiveMessageType, null: true
      field :errors, [String], null: false

      argument :app_key, String, required: true
      argument :campaign_data, Types::ProactiveMessageInputType, required: true

      def resolve(app_key:, campaign_data:)
        app = find_app(app_key)
        authorize! app, to: :can_manage_proactive_messages?, with: AppPolicy, context: { app: app }

        service = ProactiveMessageService.new(app)
        result = service.create_campaign(campaign_data.to_h)

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

    class UpdateCampaign < Mutations::BaseMutation
      field :proactive_message, Types::ProactiveMessageType, null: true
      field :errors, [String], null: false

      argument :app_key, String, required: true
      argument :campaign_id, ID, required: true
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

    class TestCampaign < Mutations::BaseMutation
      field :test_result, GraphQL::Types::JSON, null: true
      field :errors, [String], null: false

      argument :app_key, String, required: true
      argument :campaign_id, ID, required: true
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

    class ToggleCampaign < Mutations::BaseMutation
      field :proactive_message, Types::ProactiveMessageType, null: true
      field :errors, [String], null: false

      argument :app_key, String, required: true
      argument :campaign_id, ID, required: true

      def resolve(app_key:, campaign_id:)
        app = find_app(app_key)
        authorize! app, to: :can_manage_proactive_messages?, with: AppPolicy, context: { app: app }

        service = ProactiveMessageService.new(app)
        result = service.toggle_campaign_status(campaign_id)

        if result[:success]
          {
            proactive_message: result[:message],
            errors: []
          }
        else
          {
            proactive_message: nil,
            errors: ["Failed to toggle campaign status"]
          }
        end
      end

      private

      def find_app(app_key)
        current_user.apps.find_by(key: app_key) || raise(GraphQL::ExecutionError, "App not found")
      end
    end

    class DuplicateCampaign < Mutations::BaseMutation
      field :proactive_message, Types::ProactiveMessageType, null: true
      field :errors, [String], null: false

      argument :app_key, String, required: true
      argument :campaign_id, ID, required: true

      def resolve(app_key:, campaign_id:)
        app = find_app(app_key)
        authorize! app, to: :can_manage_proactive_messages?, with: AppPolicy, context: { app: app }

        service = ProactiveMessageService.new(app)
        result = service.duplicate_campaign(campaign_id)

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