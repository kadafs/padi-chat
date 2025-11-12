# frozen_string_literal: true

module Types
  class ContactListMembershipType < Types::BaseObject
    field :id, ID, null: false
    field :contact_list, Types::ContactListType, null: false
    field :app_user, Types::AppUserType, null: false
    field :added_at, GraphQL::Types::ISO8601DateTime, null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
  end
end


