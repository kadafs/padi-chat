# frozen_string_literal: true

module Types
  # Define edge/connection types at the Types namespace level
  class ProactiveMessageEdgeType < Types::BaseEdge
    node_type(Types::ProactiveMessageType)
  end

  class ProactiveMessageConnectionType < Types::BaseConnection
    edge_type(Types::ProactiveMessageEdgeType)
  end

  module QueryTypeExtensions
    module ProactiveMessageQueries
      extend ActiveSupport::Concern

      included do
        field :proactive_messages, Types::ProactiveMessageConnectionType, null: false, connection: true do
          argument :app_key, String, required: true
          argument :status, String, required: false
          argument :trigger_type, String, required: false
          argument :search_term, String, required: false
        end

        field :proactive_message, Types::ProactiveMessageType, null: true do
          argument :app_key, String, required: true
          argument :id, GraphQL::Types::ID, required: true
        end

        field :proactive_message_analytics, Types::ProactiveMessageAnalyticsType, null: false do
          argument :app_key, String, required: true
          argument :campaign_id, GraphQL::Types::ID, required: true
          argument :time_range, String, required: false, default_value: '7d'
        end

        field :campaign_suggestions, [Types::CampaignSuggestionType], null: false do
          argument :app_key, String, required: true
          argument :visitor_patterns, GraphQL::Types::JSON, required: false
        end

        field :campaign_templates, [Types::CampaignTemplateType], null: false do
          argument :app_key, String, required: true
          argument :category, String, required: false
        end
      end

      def proactive_messages(app_key:, status: nil, trigger_type: nil, search_term: nil)
        app = find_app(app_key)
        
        messages = app.proactive_messages
        
        # Apply filters
        messages = messages.where(active: true) if status == 'active'
        messages = messages.where(active: false) if status == 'inactive'
        messages = messages.where(trigger_type: trigger_type) if trigger_type.present?
        
        if search_term.present?
          messages = messages.where('name ILIKE ?', "%#{search_term}%")
        end
        
        messages.order(created_at: :desc)
      end

      def proactive_message(app_key:, id:)
        app = find_app(app_key)
        app.proactive_messages.find_by(id: id)
      end

      def proactive_message_analytics(app_key:, campaign_id:, time_range:)
        app = find_app(app_key)
        service = ProactiveMessageService.new(app)
        service.get_campaign_analytics(campaign_id, time_range)
      end

      def campaign_suggestions(app_key:, visitor_patterns: nil)
        app = find_app(app_key)
        service = ProactiveMessageService.new(app)
        
        patterns = visitor_patterns || {
          bounce_rate: calculate_bounce_rate(app),
          avg_time_on_page: calculate_avg_time(app),
          cart_abandonment_rate: calculate_abandonment_rate(app),
          conversion_rate: calculate_conversion_rate(app)
        }
        
        service.suggest_campaigns(patterns)
      end

      def campaign_templates(app_key:, category: nil)
        app = find_app(app_key)
        
        templates = [
          {
            id: 'welcome',
            name: 'Welcome Message',
            category: 'engagement',
            description: 'Greet visitors when they land on your site',
            template: {
              trigger_type: 'time_based',
              delay_seconds: 30,
              message_content: {
                text: 'Welcome! 👋 How can we help you today?',
                quick_replies: [
                  { text: 'I have a question', value: 'question' },
                  { text: 'Just browsing', value: 'browsing' }
                ]
              }
            }
          },
          {
            id: 'exit_intent',
            name: 'Exit Intent Popup',
            category: 'conversion',
            description: 'Engage visitors before they leave',
            template: {
              trigger_type: 'exit_intent',
              message_content: {
                text: "Wait! Before you go, would you like to see our special offers?",
                quick_replies: [
                  { text: 'Show me offers', value: 'offers' },
                  { text: 'No thanks', value: 'decline' }
                ]
              }
            }
          },
          {
            id: 'cart_recovery',
            name: 'Cart Recovery',
            category: 'sales',
            description: 'Reduce cart abandonment',
            template: {
              trigger_type: 'behavior_based',
              trigger_conditions: {
                behavior_based: {
                  visited_pages: ['/cart', '/checkout'],
                  min_cart_value: 50
                }
              },
              message_content: {
                text: "Need help completing your purchase? I'm here to assist!",
                quick_replies: [
                  { text: 'Help with checkout', value: 'checkout_help' },
                  { text: 'Have questions', value: 'questions' }
                ]
              }
            }
          },
          {
            id: 'qualified_leads',
            name: 'Lead Qualification',
            category: 'leads',
            description: 'Qualify visitors based on their interests',
            template: {
              trigger_type: 'time_based',
              delay_seconds: 120,
              targeting_rules: {
                returning_only: true
              },
              message_content: {
                text: "Hi there! I noticed you're interested in our solutions. What best describes your needs?",
                quick_replies: [
                  { text: 'Enterprise', value: 'enterprise' },
                  { text: 'Small Business', value: 'smb' },
                  { text: 'Personal Use', value: 'personal' }
                ]
              }
            }
          }
        ]

        if category.present?
          templates = templates.select { |t| t[:category] == category }
        end

        templates
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

      def calculate_bounce_rate(app)
        sessions = app.visitor_sessions.where('created_at > ?', 24.hours.ago)
        total = sessions.count
        bounced = sessions.where('page_views = 1').count
        
        return 0 if total.zero?
        ((bounced.to_f / total) * 100).round(2)
      end

      def calculate_avg_time(app)
        app.visitor_sessions
           .where('created_at > ?', 24.hours.ago)
           .average(:time_on_site)
           .to_i
      end

      def calculate_abandonment_rate(app)
        # This would need proper e-commerce tracking
        # Mock implementation
        rand(40..70)
      end

      def calculate_conversion_rate(app)
        sessions = app.visitor_sessions.where('created_at > ?', 24.hours.ago)
        total = sessions.count
        converted = app.conversations
                      .where('created_at > ?', 24.hours.ago)
                      .distinct
                      .count('app_user_id')
        
        return 0 if total.zero?
        ((converted.to_f / total) * 100).round(2)
      end
    end
  end

  class CampaignSuggestionType < Types::BaseObject
    field :type, String, null: false
    field :title, String, null: false
    field :description, String, null: false
    field :template, GraphQL::Types::JSON, null: false
  end

  class CampaignTemplateType < Types::BaseObject
    field :id, String, null: false
    field :name, String, null: false
    field :category, String, null: false
    field :description, String, null: false
    field :template, GraphQL::Types::JSON, null: false
  end
end