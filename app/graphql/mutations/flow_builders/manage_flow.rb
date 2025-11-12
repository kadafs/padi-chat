# frozen_string_literal: true

module Mutations
  module FlowBuilders
    class CreateFlow < Mutations::BaseMutation
      field :flow_builder, Types::FlowBuilderType, null: true
      field :errors, [String], null: false

      argument :app_key, String, required: true
      argument :name, String, required: true
      argument :description, String, required: false
      argument :flow_type, String, required: true
      argument :flow_data, GraphQL::Types::JSON, required: false
      argument :triggers, GraphQL::Types::JSON, required: false
      argument :active, Boolean, required: false, default_value: true

      def resolve(app_key:, name:, description: nil, flow_type:, flow_data: {}, triggers: {}, active: true)
        app = find_app(app_key)
        authorize! app, to: :can_manage_bots?, with: AppPolicy, context: { app: app }

        flow_builder = app.flow_builders.create!(
          name: name,
          description: description,
          flow_type: flow_type,
          flow_data: flow_data,
          triggers: triggers,
          active: active
        )

        {
          flow_builder: flow_builder,
          errors: []
        }
      rescue StandardError => e
        {
          flow_builder: nil,
          errors: [e.message]
        }
      end

      private

      def find_app(app_key)
        current_user.apps.find_by(key: app_key) || raise(GraphQL::ExecutionError, "App not found")
      end
    end

    class UpdateFlow < Mutations::BaseMutation
      field :flow_builder, Types::FlowBuilderType, null: true
      field :errors, [String], null: false

      argument :app_key, String, required: true
      argument :flow_id, ID, required: true
      argument :name, String, required: false
      argument :description, String, required: false
      argument :flow_data, GraphQL::Types::JSON, required: false
      argument :triggers, GraphQL::Types::JSON, required: false
      argument :active, Boolean, required: false

      def resolve(app_key:, flow_id:, **args)
        app = find_app(app_key)
        authorize! app, to: :can_manage_bots?, with: AppPolicy, context: { app: app }

        flow_builder = app.flow_builders.find(flow_id)
        flow_builder.update!(args.compact)

        {
          flow_builder: flow_builder,
          errors: []
        }
      rescue StandardError => e
        {
          flow_builder: nil,
          errors: [e.message]
        }
      end

      private

      def find_app(app_key)
        current_user.apps.find_by(key: app_key) || raise(GraphQL::ExecutionError, "App not found")
      end
    end

    class DeleteFlow < Mutations::BaseMutation
      field :success, Boolean, null: false
      field :errors, [String], null: false

      argument :app_key, String, required: true
      argument :flow_id, ID, required: true

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

    class DuplicateFlow < Mutations::BaseMutation
      field :flow_builder, Types::FlowBuilderType, null: true
      field :errors, [String], null: false

      argument :app_key, String, required: true
      argument :flow_id, ID, required: true

      def resolve(app_key:, flow_id:)
        app = find_app(app_key)
        authorize! app, to: :can_manage_bots?, with: AppPolicy, context: { app: app }

        flow_builder = app.flow_builders.find(flow_id)
        duplicated = flow_builder.duplicate!

        {
          flow_builder: duplicated,
          errors: []
        }
      rescue StandardError => e
        {
          flow_builder: nil,
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


