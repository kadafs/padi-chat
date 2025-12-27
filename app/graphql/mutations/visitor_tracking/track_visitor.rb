# frozen_string_literal: true

module Mutations
  module VisitorTracking
    class TrackVisitor < Mutations::BaseMutation
      field :visitor_session, Types::VisitorSessionType, null: true
      field :errors, [String], null: false

      argument :app_key, String, required: true
      argument :session_id, String, required: false
      argument :user_id, String, required: false
      argument :email, String, required: false
      argument :first_name, String, required: false
      argument :last_name, String, required: false
      argument :referrer, String, required: false
      argument :landing_page, String, required: false
      argument :current_page, String, required: false
      argument :user_agent, String, required: false
      argument :country_code, String, required: false
      argument :city, String, required: false
      argument :ip_address, String, required: false
      argument :utm_source, String, required: false
      argument :utm_medium, String, required: false
      argument :utm_campaign, String, required: false
      argument :utm_term, String, required: false
      argument :utm_content, String, required: false
      argument :custom_attributes, GraphQL::Types::JSON, required: false
      argument :geolocation, GraphQL::Types::JSON, required: false

      def resolve(app_key:, **args)
        app = App.find_by(key: app_key)
        return { visitor_session: nil, errors: ["App not found"] } unless app

        tracking_service = VisitorTrackingService.new(app)
        visitor_session = tracking_service.track_visitor(args)

        if visitor_session
          # Check for proactive messages after tracking
          check_proactive_triggers(visitor_session)
          
          {
            visitor_session: visitor_session,
            errors: []
          }
        else
          {
            visitor_session: nil,
            errors: ["Failed to track visitor"]
          }
        end
      end

      private

      def check_proactive_triggers(visitor_session)
        service = ProactiveMessageService.new(visitor_session.app)
        triggered_campaigns = service.check_campaigns_for_session(visitor_session)

        # Execute the highest priority campaign if any
        if triggered_campaigns.any?
          campaign = triggered_campaigns.first[:campaign]
          service.execute_campaign(campaign, visitor_session)
        end
      end
    end

    class UpdateVisitorActivity < Mutations::BaseMutation
      field :visitor_session, Types::VisitorSessionType, null: true
      field :errors, [String], null: false

      argument :app_key, String, required: true
      argument :session_id, String, required: true
      argument :current_page, String, required: false
      argument :custom_attributes, GraphQL::Types::JSON, required: false

      def resolve(app_key:, session_id:, **args)
        app = App.find_by(key: app_key)
        return { visitor_session: nil, errors: ["App not found"] } unless app

        tracking_service = VisitorTrackingService.new(app)
        visitor_session = tracking_service.update_activity(session_id, args)

        if visitor_session
          # Check for proactive messages after activity update
          check_proactive_triggers(visitor_session)
          
          {
            visitor_session: visitor_session,
            errors: []
          }
        else
          {
            visitor_session: nil,
            errors: ["Session not found"]
          }
        end
      end

      private

      def check_proactive_triggers(visitor_session)
        service = ProactiveMessageService.new(visitor_session.app)
        triggered_campaigns = service.check_campaigns_for_session(visitor_session)

        # Execute the highest priority campaign if any
        if triggered_campaigns.any?
          campaign = triggered_campaigns.first[:campaign]
          service.execute_campaign(campaign, visitor_session)
        end
      end
    end

    class TrackEvent < Mutations::BaseMutation
      field :success, GraphQL::Types::Boolean, null: false
      field :errors, [String], null: false

      argument :app_key, String, required: true
      argument :session_id, String, required: true
      argument :event_name, String, required: true
      argument :event_data, GraphQL::Types::JSON, required: false

      def resolve(app_key:, session_id:, event_name:, event_data: nil)
        app = App.find_by(key: app_key)
        return { success: false, errors: ["App not found"] } unless app

        tracking_service = VisitorTrackingService.new(app)
        result = tracking_service.track_event(session_id, event_name, event_data)

        if result
          # Check for flow triggers based on event
          check_flow_triggers(app, session_id, event_name, event_data)
          
          {
            success: true,
            errors: []
          }
        else
          {
            success: false,
            errors: ["Failed to track event"]
          }
        end
      end

      private

      def check_flow_triggers(app, session_id, event_name, event_data)
        visitor_session = app.visitor_sessions.find_by(session_id: session_id)
        return unless visitor_session

        FlowBuilder.active.find_each do |flow|
          next unless flow.triggers&.dig('custom_event', 'event_name') == event_name

          FlowExecutionJob.perform_later(
            flow.id,
            visitor_session.id,
            {
              event_name: event_name,
              event_data: event_data
            }
          )
        end
      end
    end
  end
end
