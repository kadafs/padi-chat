# frozen_string_literal: true

module Types
  module QueryTypeExtensions
    module VisitorTrackingQueries
      extend ActiveSupport::Concern

      included do
        field :visitor_analytics, Types::VisitorAnalyticsType, null: false do
          argument :app_key, String, required: true
          argument :time_range, String, required: false, default_value: '24h'
        end

        field :live_visitors, [Types::VisitorSessionType], null: false do
          argument :app_key, String, required: true
          argument :limit, Integer, required: false, default_value: 50
        end

        field :visitor_session, Types::VisitorSessionType, null: true do
          argument :app_key, String, required: true
          argument :session_id, String, required: true
        end

        field :visitor_journey, [Types::VisitorJourneyEntryType], null: false do
          argument :app_key, String, required: true
          argument :session_id, String, required: true
        end

        field :visitor_segments, [Types::VisitorSegmentType], null: false do
          argument :app_key, String, required: true
          argument :filters, GraphQL::Types::JSON, required: false
        end
      end

      def visitor_analytics(app_key:, time_range:)
        app = find_app(app_key)
        tracking_service = VisitorTrackingService.new(app)
        tracking_service.get_analytics(time_range)
      end

      def live_visitors(app_key:, limit:)
        app = find_app(app_key)
        tracking_service = VisitorTrackingService.new(app)
        tracking_service.get_live_visitors(limit)
      end

      def visitor_session(app_key:, session_id:)
        app = find_app(app_key)
        app.visitor_sessions.find_by(session_id: session_id)
      end

      def visitor_journey(app_key:, session_id:)
        app = find_app(app_key)
        tracking_service = VisitorTrackingService.new(app)
        tracking_service.get_visitor_journey(session_id)
      end

      def visitor_segments(app_key:, filters: nil)
        app = find_app(app_key)
        
        segments = app.visitor_sessions
                     .joins(:app_user)
                     .group('app_users.id')
                     .select('app_users.*, COUNT(visitor_sessions.id) as visit_count')

        if filters
          segments = apply_segment_filters(segments, filters)
        end

        segments.map do |segment|
          {
            id: segment.id,
            name: segment.name || 'Anonymous',
            visit_count: segment.visit_count,
            last_seen_at: segment.last_activity_at,
            total_time_on_site: segment.time_on_site,
            conversion_rate: calculate_conversion_rate(segment)
          }
        end
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

      def apply_segment_filters(segments, filters)
        segments = segments.where(device_type: filters[:device_type]) if filters[:device_type]
        segments = segments.where(country_code: filters[:country]) if filters[:country]
        
        if filters[:time_on_site_min]
          segments = segments.where('time_on_site >= ?', filters[:time_on_site_min])
        end
        
        if filters[:page_views_min]
          segments = segments.where('page_views >= ?', filters[:page_views_min])
        end
        
        if filters[:is_returning] == true
          segments = segments.where(is_returning: true)
        end
        
        if filters[:has_conversation] == true
          segments = segments.joins(:conversations).distinct
        end
        
        segments
      end

      def calculate_conversion_rate(segment)
        total_visits = segment.visit_count
        converted_visits = segment.conversations.count
        
        return 0 if total_visits.zero?
        ((converted_visits.to_f / total_visits) * 100).round(2)
      end
    end
  end

  class LocationBreakdownType < Types::BaseObject
    field :country, String, null: false
    field :visitors, Integer, null: false
  end

  class HourlyActivityType < Types::BaseObject
    field :hour, Integer, null: false
    field :visitors, Integer, null: false
  end

  class PopularPageType < Types::BaseObject
    field :page, String, null: false
    field :views, Integer, null: false
  end

  class VisitorAnalyticsType < Types::BaseObject
    field :total_visitors, Integer, null: false
    field :online_visitors, Integer, null: false
    field :unique_visitors, Integer, null: false
    field :returning_visitors, Integer, null: false
    field :average_time_on_site, Integer, null: false
    field :total_page_views, Integer, null: false
    field :device_breakdown, GraphQL::Types::JSON, null: false
    field :location_breakdown, [Types::LocationBreakdownType], null: false
    field :traffic_sources, GraphQL::Types::JSON, null: false
    field :hourly_activity, [Types::HourlyActivityType], null: false
    field :popular_pages, [Types::PopularPageType], null: false
  end

  class VisitorSegmentType < Types::BaseObject
    field :id, ID, null: false
    field :name, String, null: false
    field :visit_count, Integer, null: false
    field :last_seen_at, GraphQL::Types::ISO8601DateTime, null: true
    field :total_time_on_site, Integer, null: false
    field :conversion_rate, Float, null: false
  end
end