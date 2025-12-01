# frozen_string_literal: true

module Types
  class VisitorJourneyEntryType < Types::BaseObject
    field :url, String, null: false
    field :title, String, null: true
    field :timestamp, GraphQL::Types::ISO8601DateTime, null: false
    field :duration, Integer, null: true
  end

  class VisitorEventType < Types::BaseObject
    field :name, String, null: false
    field :data, GraphQL::Types::JSON, null: true
    field :timestamp, GraphQL::Types::ISO8601DateTime, null: false
  end

  class VisitorSessionType < Types::BaseObject
    field :id, ID, null: false
    field :session_id, String, null: false
    field :app_user, Types::AppUserType, null: false
    field :referrer_url, String, null: true
    field :landing_page, String, null: true
    field :current_page, String, null: true
    field :utm_parameters, GraphQL::Types::JSON, null: true
    field :device_type, String, null: true
    field :browser, String, null: true
    field :os, String, null: true
    field :country_code, String, null: true
    field :city, String, null: true
    field :ip_address, String, null: true
    field :geolocation, GraphQL::Types::JSON, null: true
    field :page_views, Integer, null: false
    field :time_on_site, Integer, null: false
    field :is_returning, Boolean, null: false
    field :is_online, Boolean, null: false
    field :custom_attributes, GraphQL::Types::JSON, null: true
    field :first_seen_at, GraphQL::Types::ISO8601DateTime, null: true
    field :last_activity_at, GraphQL::Types::ISO8601DateTime, null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

    # Computed fields
    field :location_string, String, null: true
    field :duration_formatted, String, null: true
    field :lead_score, Integer, null: true

    def location_string
      [object.city, object.country_code].compact.join(', ')
    end

    def duration_formatted
      seconds = object.time_on_site
      return "0s" if seconds <= 0
      
      hours = seconds / 3600
      minutes = (seconds % 3600) / 60
      remaining_seconds = seconds % 60
      
      if hours > 0
        "#{hours}h #{minutes}m"
      elsif minutes > 0
        "#{minutes}m #{remaining_seconds}s"
      else
        "#{remaining_seconds}s"
      end
    end

    def is_online
      object.last_activity_at && object.last_activity_at > 5.minutes.ago
    end

    def lead_score
      VisitorTrackingService.new(object.app).calculate_visitor_score(object)
    end

    # Analytics fields
    field :journey, [Types::VisitorJourneyEntryType], null: false
    field :events, [Types::VisitorEventType], null: false
    field :conversations, [Types::ConversationType], null: false

    def journey
      object.custom_attributes&.dig('page_views') || []
    end

    def events
      object.custom_attributes&.dig('events') || []
    end

    def conversations
      object.app_user.conversations.order(created_at: :desc)
    end
  end
end