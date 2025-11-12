# frozen_string_literal: true

module Types
  class FlowBuilderType < Types::BaseObject
    field :id, ID, null: false
    field :app, Types::AppType, null: false
    field :name, String, null: false
    field :description, String, null: true
    field :flow_type, String, null: true
    field :flow_data, GraphQL::Types::JSON, null: false
    field :triggers, GraphQL::Types::JSON, null: false
    field :active, Boolean, null: false
    field :position, Integer, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

    field :nodes, [GraphQL::Types::JSON], null: false
    field :connections, [GraphQL::Types::JSON], null: false
    field :start_node, GraphQL::Types::JSON, null: true
    field :flow_stats, GraphQL::Types::JSON, null: false

    def nodes
      object.nodes
    end

    def connections
      object.connections
    end

    def start_node
      object.start_node
    end

    def flow_stats
      object.flow_stats
    end
  end
end

