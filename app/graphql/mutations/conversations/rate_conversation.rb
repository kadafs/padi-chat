# frozen_string_literal: true

module Mutations
  module Conversations
    class RateConversation < Mutations::BaseMutation
      field :chat_rating, Types::ChatRatingType, null: true
      field :errors, [String], null: false

      argument :app_key, String, required: true
      argument :conversation_key, String, required: true
      argument :rating, Integer, required: true
      argument :feedback, String, required: false
      argument :rating_type, String, required: false

      def resolve(app_key:, conversation_key:, rating:, feedback: nil, rating_type: 'conversation')
        app = find_app(app_key)
        authorize! app, to: :can_manage_conversations?, with: AppPolicy, context: { app: app }

        conversation = app.conversations.find_by(key: conversation_key)
        return { chat_rating: nil, errors: ["Conversation not found"] } unless conversation

        app_user = conversation.main_participant
        return { chat_rating: nil, errors: ["Participant not found"] } unless app_user

        # Validate rating
        unless (1..5).include?(rating)
          return { chat_rating: nil, errors: ["Rating must be between 1 and 5"] }
        end

        chat_rating = ChatRating.create!(
          conversation: conversation,
          app_user: app_user,
          agent: conversation.assignee,
          rating: rating,
          feedback: feedback,
          rating_type: rating_type
        )

        # Update conversation rating
        conversation.update!(conversation_rating: rating)

        # Update conversation analytics if exists
        analytics = conversation.conversation_analytics || conversation.build_conversation_analytics
        analytics.update!(rating: rating)
        analytics.calculate_metrics!

        {
          chat_rating: chat_rating,
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


