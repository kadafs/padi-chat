# frozen_string_literal: true

module Types
  class TriggerPageType < Types::BaseObject
    field :page, String, null: false
    field :triggers, Integer, null: false
  end

  class HourlyPerformanceType < Types::BaseObject
    field :hour, Integer, null: false
    field :triggers, Integer, null: false
    field :conversations, Integer, null: false
  end

  class ProactiveMessageAnalyticsType < Types::BaseObject
    field :impressions, Integer, null: false
    field :conversations_started, Integer, null: false
    field :conversion_rate, Float, null: false
    field :average_response_time, Integer, null: false
    
    field :top_trigger_pages, [Types::TriggerPageType], null: false
    field :hourly_performance, [Types::HourlyPerformanceType], null: false
    field :device_breakdown, GraphQL::Types::JSON, null: false
  end

  class ProactiveMessageType < Types::BaseObject
    field :id, GraphQL::Types::ID, null: false
    field :name, String, null: false
    field :trigger_type, String, null: false
    field :delay_seconds, Integer, null: false
    field :message_content, GraphQL::Types::JSON, null: false
    field :trigger_conditions, GraphQL::Types::JSON, null: true
    field :targeting_rules, GraphQL::Types::JSON, null: true
    field :active, GraphQL::Types::Boolean, null: false
    field :priority, Integer, null: false
    field :schedule, GraphQL::Types::JSON, null: true
    field :start_date, GraphQL::Types::ISO8601DateTime, null: true
    field :end_date, GraphQL::Types::ISO8601DateTime, null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

    # Computed fields
    field :formatted_message, GraphQL::Types::JSON, null: false
    field :targeting_summary, String, null: false
    field :status, String, null: false

    # Analytics fields
    field :analytics, Types::ProactiveMessageAnalyticsType, null: false do
      argument :time_range, String, required: false, default_value: '7d'
    end

    def formatted_message
      object.formatted_message
    end

    def targeting_summary
      object.targeting_summary
    end

    def status
      if !object.active?
        'inactive'
      elsif !object.within_date_range?
        'scheduled'
      elsif !object.within_schedule?
        'outside_schedule'
      else
        'active'
      end
    end

    def analytics(time_range:)
      ProactiveMessageService.new(object.app).get_campaign_analytics(object.id, time_range)
    end
  end

  class ProactiveMessageInputType < Types::BaseInputObject
    argument :name, String, required: true
    argument :trigger_type, String, required: true
    argument :delay_seconds, Integer, required: true
    argument :message_content, GraphQL::Types::JSON, required: true
    argument :trigger_conditions, GraphQL::Types::JSON, required: false
    argument :targeting_rules, GraphQL::Types::JSON, required: false
    argument :active, GraphQL::Types::Boolean, required: false
    argument :priority, Integer, required: false
    argument :schedule, GraphQL::Types::JSON, required: false
    argument :start_date, GraphQL::Types::ISO8601DateTime, required: false
    argument :end_date, GraphQL::Types::ISO8601DateTime, required: false
  end
end
