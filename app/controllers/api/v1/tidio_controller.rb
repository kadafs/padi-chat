# frozen_string_literal: true

module Api
  module V1
    class TidioController < ApiController
      before_action :authenticate_user!
      before_action :set_app
      before_action :authorize_app!
      
      def track_visitor
        tracking_service = VisitorTrackingService.new(@app)
        visitor_session = tracking_service.track_visitor(visitor_params)
        
        if visitor_session
          render json: {
            success: true,
            session_id: visitor_session.session_id,
            visitor_data: format_visitor_data(visitor_session)
          }
        else
          render json: { success: false, error: 'Failed to track visitor' }, status: :unprocessable_entity
        end
      end

      def update_visitor_activity
        tracking_service = VisitorTrackingService.new(@app)
        visitor_session = tracking_service.update_activity(
          params[:session_id],
          activity_params
        )
        
        if visitor_session
          render json: {
            success: true,
            visitor_data: format_visitor_data(visitor_session)
          }
        else
          render json: { success: false, error: 'Session not found' }, status: :not_found
        end
      end

      def track_event
        tracking_service = VisitorTrackingService.new(@app)
        result = tracking_service.track_event(
          params[:session_id],
          params[:event_name],
          params[:event_data]
        )
        
        if result
          render json: { success: true }
        else
          render json: { success: false, error: 'Failed to track event' }, status: :unprocessable_entity
        end
      end

      def visitor_analytics
        tracking_service = VisitorTrackingService.new(@app)
        analytics = tracking_service.get_analytics(params[:time_range])
        
        render json: {
          success: true,
          analytics: analytics
        }
      end

      def live_visitors
        tracking_service = VisitorTrackingService.new(@app)
        visitors = tracking_service.get_live_visitors(params[:limit])
        
        render json: {
          success: true,
          visitors: visitors
        }
      end

      def visitor_journey
        tracking_service = VisitorTrackingService.new(@app)
        journey = tracking_service.get_visitor_journey(params[:session_id])
        
        render json: {
          success: true,
          journey: journey
        }
      end

      # Proactive Messages API

      def create_proactive_campaign
        service = ProactiveMessageService.new(@app)
        result = service.create_campaign(proactive_campaign_params)
        
        if result[:success]
          render json: {
            success: true,
            campaign: result[:message]
          }
        else
          render json: { 
            success: false, 
            errors: result[:errors] 
          }, status: :unprocessable_entity
        end
      end

      def update_proactive_campaign
        service = ProactiveMessageService.new(@app)
        result = service.update_campaign(
          params[:id],
          proactive_campaign_params
        )
        
        if result[:success]
          render json: {
            success: true,
            campaign: result[:message]
          }
        else
          render json: { 
            success: false, 
            errors: result[:errors] 
          }, status: :unprocessable_entity
        end
      end

      def test_proactive_campaign
        service = ProactiveMessageService.new(@app)
        result = service.test_campaign(
          params[:id],
          params[:sample_visitor_data]
        )
        
        render json: {
          success: true,
          test_result: result
        }
      end

      def campaign_analytics
        service = ProactiveMessageService.new(@app)
        analytics = service.get_campaign_analytics(
          params[:id],
          params[:time_range]
        )
        
        render json: {
          success: true,
          analytics: analytics
        }
      end

      def toggle_campaign
        service = ProactiveMessageService.new(@app)
        result = service.toggle_campaign_status(params[:id])
        
        render json: {
          success: true,
          status: result[:status],
          campaign: result[:message]
        }
      end

      def duplicate_campaign
        service = ProactiveMessageService.new(@app)
        result = service.duplicate_campaign(params[:id])
        
        if result[:success]
          render json: {
            success: true,
            campaign: result[:message]
          }
        else
          render json: { 
            success: false, 
            errors: result[:errors] 
          }, status: :unprocessable_entity
        end
      end

      def campaign_suggestions
        service = ProactiveMessageService.new(@app)
        suggestions = service.suggest_campaigns(visitor_patterns_params)
        
        render json: {
          success: true,
          suggestions: suggestions
        }
      end

      private

      def set_app
        @app = current_user.apps.find(params[:app_id])
      end

      def authorize_app!
        authorize! @app, to: :manage?
      end

      def visitor_params
        params.permit(
          :session_id,
          :user_id,
          :email,
          :first_name,
          :last_name,
          :referrer,
          :landing_page,
          :current_page,
          :user_agent,
          :country_code,
          :city,
          :ip_address,
          :utm_source,
          :utm_medium,
          :utm_campaign,
          :utm_term,
          :utm_content,
          custom_attributes: {},
          geolocation: {}
        )
      end

      def activity_params
        params.permit(
          :current_page,
          custom_attributes: {}
        )
      end

      def proactive_campaign_params
        params.permit(
          :name,
          :trigger_type,
          :delay_seconds,
          :priority,
          :active,
          :start_date,
          :end_date,
          message_content: [
            :text,
            :avatar,
            { quick_replies: [:text, :value] },
            { attachments: [:url, :caption] }
          ],
          trigger_conditions: {},
          targeting_rules: {},
          schedule: {}
        )
      end

      def visitor_patterns_params
        params.permit(
          :bounce_rate,
          :avg_time_on_page,
          :cart_abandonment_rate,
          :conversion_rate,
          patterns: {}
        )
      end

      def format_visitor_data(session)
        {
          id: session.id,
          session_id: session.session_id,
          name: session.app_user.display_name,
          email: session.app_user.email,
          location: session.location_string,
          device: session.device_type,
          browser: session.browser,
          current_page: session.current_page,
          time_on_site: session.duration_formatted,
          page_views: session.page_views,
          is_returning: session.is_returning,
          is_online: session.is_active?,
          custom_attributes: session.custom_attributes
        }
      end
    end
  end
end