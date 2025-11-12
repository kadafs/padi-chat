# frozen_string_literal: true

class ConversationAnalytics < ApplicationRecord
  belongs_to :conversation

  validates :conversation_id, uniqueness: true

  # Tidio-like analytics calculations
  def calculate_metrics!
    update!(
      first_response_time_seconds: calculate_first_response_time,
      resolution_time_seconds: calculate_resolution_time,
      agent_messages_count: count_agent_messages,
      customer_messages_count: count_customer_messages,
      bot_messages_count: count_bot_messages,
      escalated_to_human: check_escalation
    )
  end

  def first_response_time_formatted
    return 'N/A' unless first_response_time_seconds

    if first_response_time_seconds < 60
      "#{first_response_time_seconds}s"
    elsif first_response_time_seconds < 3600
      "#{(first_response_time_seconds / 60).round}m"
    else
      "#{(first_response_time_seconds / 3600).round(1)}h"
    end
  end

  def resolution_time_formatted
    return 'N/A' unless resolution_time_seconds

    if resolution_time_seconds < 60
      "#{resolution_time_seconds}s"
    elsif resolution_time_seconds < 3600
      "#{(resolution_time_seconds / 60).round}m"
    else
      "#{(resolution_time_seconds / 3600).round(1)}h"
    end
  end

  private

  def calculate_first_response_time
    return nil unless first_response_at && conversation.created_at

    (first_response_at - conversation.created_at).to_i
  end

  def calculate_resolution_time
    return nil unless resolution_at && conversation.created_at

    (resolution_at - conversation.created_at).to_i
  end

  def count_agent_messages
    conversation.messages
                .where(authorable_type: 'Agent')
                .count
  end

  def count_customer_messages
    conversation.messages
                .where(authorable_type: 'AppUser')
                .count
  end

  def count_bot_messages
    conversation.messages
                .where(message_source: ['bot', 'flow_builder'])
                .count
  end

  def check_escalation
    conversation.messages
                .where(authorable_type: 'Agent')
                .exists?
  end
end

