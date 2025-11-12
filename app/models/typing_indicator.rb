# frozen_string_literal: true

class TypingIndicator < ApplicationRecord
  belongs_to :conversation
  belongs_to :user, polymorphic: true

  scope :active, -> { where(is_typing: true) }
  scope :for_conversation, ->(conversation_id) { where(conversation_id: conversation_id) }

  # Tidio-like typing indicator management
  def self.start_typing(conversation, user)
    indicator = find_or_initialize_by(
      conversation: conversation,
      user: user
    )
    
    indicator.update!(
      is_typing: true,
      started_typing_at: Time.current,
      stopped_typing_at: nil
    )

    # Broadcast typing status
    broadcast_typing_status(conversation, user, true)
    
    indicator
  end

  def self.stop_typing(conversation, user)
    indicator = find_by(
      conversation: conversation,
      user: user,
      is_typing: true
    )
    
    return unless indicator

    indicator.update!(
      is_typing: false,
      stopped_typing_at: Time.current
    )

    # Broadcast typing status
    broadcast_typing_status(conversation, user, false)
    
    indicator
  end

  def self.broadcast_typing_status(conversation, user, is_typing)
    # Broadcast via ActionCable/AnyCable
    broadcast_key = conversation.broadcast_key
    MessengerEventsChannel.broadcast_to(
      broadcast_key,
      {
        type: 'typing_indicator',
        data: {
          user_id: user.id,
          user_type: user.class.name,
          is_typing: is_typing
        }
      }
    )
  end

  # Clean up old typing indicators (run periodically)
  def self.cleanup_stale_indicators
    where('is_typing = true AND started_typing_at < ?', 30.seconds.ago)
      .update_all(
        is_typing: false,
        stopped_typing_at: Time.current
      )
  end
end

