# frozen_string_literal: true

module Types
  module QueryTypeExtensions
    module FlowBuilderQueries
      extend ActiveSupport::Concern

      included do
        field :flow_builders, [Types::FlowBuilderType], null: false do
          argument :app_key, String, required: true
          argument :flow_type, String, required: false
          argument :active_only, Boolean, required: false, default_value: false
        end

        field :flow_builder, Types::FlowBuilderType, null: true do
          argument :app_key, String, required: true
          argument :id, ID, required: true
        end
      end

      def flow_builders(app_key:, flow_type: nil, active_only: false)
        app = find_app(app_key)
        flows = app.flow_builders

        flows = flows.where(flow_type: flow_type) if flow_type.present?
        flows = flows.where(active: true) if active_only

        flows.order(:position)
      end

      def flow_builder(app_key:, id:)
        app = find_app(app_key)
        app.flow_builders.find_by(id: id)
      end

      private

      def find_app(app_key)
        app = App.find_by(key: app_key)
        raise GraphQL::ExecutionError, "App not found" unless app
        
        unless context[:current_user]&.apps&.include?(app)
          raise GraphQL::ExecutionError, "Not authorized to access this app"
        end
        
        app
      end
    end
  end
end


