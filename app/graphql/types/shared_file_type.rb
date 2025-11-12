# frozen_string_literal: true

module Types
  class SharedFileType < Types::BaseObject
    field :id, ID, null: false
    field :conversation, Types::ConversationType, null: false
    field :sender, Types::AuthorType, null: false
    field :file_name, String, null: false
    field :file_type, String, null: true
    field :file_size, Integer, null: true
    field :file_url, String, null: true
    field :thumbnail_url, String, null: true
    field :is_image, Boolean, null: false, default_value: false
    field :is_document, Boolean, null: false, default_value: false
    field :metadata, GraphQL::Types::JSON, null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

    field :file_size_formatted, String, null: true

    def file_size_formatted
      object.file_size_formatted
    end
  end
end


