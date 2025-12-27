# frozen_string_literal: true

module Types
  module QueryTypeExtensions
    module EmailSequenceQueries
      extend ActiveSupport::Concern

      included do
        field :email_sequences, [Types::EmailSequenceType], null: false, description: "Get email sequences" do
          argument :app_key, String, required: true
          argument :status, String, required: false
          argument :trigger_event, String, required: false
        end

        field :email_sequence, Types::EmailSequenceType, null: true, description: "Get a single email sequence" do
          argument :app_key, String, required: true
          argument :id, GraphQL::Types::ID, required: true
        end
      end

      def email_sequences(app_key:, status: nil, trigger_event: nil)
        app = find_app(app_key)

        sequences = app.email_sequences
        sequences = sequences.active if status == 'active'
        sequences = sequences.where(active: false) if status == 'inactive'
        sequences = sequences.by_trigger(trigger_event) if trigger_event.present?
        
        sequences.order(created_at: :desc)
      end

      def email_sequence(app_key:, id:)
        app = find_app(app_key)
        app.email_sequences.find_by(id: id)
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

