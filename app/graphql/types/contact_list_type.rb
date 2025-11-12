# frozen_string_literal: true

module Types
  class ContactListType < Types::BaseObject
    field :id, ID, null: false
    field :app, Types::AppType, null: false
    field :name, String, null: false
    field :description, String, null: true
    field :is_dynamic, Boolean, null: false, default_value: false
    field :filter_criteria, GraphQL::Types::JSON, null: true
    field :contacts_count, Integer, null: false, default_value: 0
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

    field :members, [Types::AppUserType], null: false
    field :memberships, [Types::ContactListMembershipType], null: false

    def members
      object.app_users.limit(100)
    end

    def memberships
      object.contact_list_memberships.order(added_at: :desc).limit(100)
    end
  end
end


