# frozen_string_literal: true

module Types
  class WidgetThemeType < Types::BaseObject
    field :id, ID, null: false
    field :app, Types::AppType, null: false
    field :name, String, null: false
    field :description, String, null: true
    field :theme_config, GraphQL::Types::JSON, null: true
    field :is_active, Boolean, null: false, default_value: false
    field :is_default, Boolean, null: false, default_value: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
  end
end


