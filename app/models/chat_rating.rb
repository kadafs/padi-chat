# frozen_string_literal: true

class ChatRating < ApplicationRecord
  belongs_to :conversation
  belongs_to :app_user
  belongs_to :agent, optional: true

  validates :rating, presence: true, inclusion: { in: 1..5 }
  validates :rating_type, inclusion: { 
    in: %w[conversation agent overall], 
    allow_nil: true 
  }

  scope :positive, -> { where('rating >= 4') }
  scope :negative, -> { where('rating <= 2') }
  scope :by_type, ->(type) { where(rating_type: type) }
  scope :recent, -> { order(created_at: :desc) }

  # Tidio-like rating analytics
  def self.average_rating_for_conversation(conversation_id)
    where(conversation_id: conversation_id, rating_type: 'conversation')
      .average(:rating)
      &.round(2)
  end

  def self.average_rating_for_agent(agent_id)
    where(agent_id: agent_id, rating_type: 'agent')
      .average(:rating)
      &.round(2)
  end

  def positive?
    rating >= 4
  end

  def negative?
    rating <= 2
  end
end


