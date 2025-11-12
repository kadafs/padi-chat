# frozen_string_literal: true

class EmailSequenceExecution < ApplicationRecord
  belongs_to :email_sequence
  belongs_to :app_user

  validates :status, inclusion: { in: %w[started in_progress completed cancelled failed] }

  scope :active, -> { where(status: %w[started in_progress]) }
  scope :completed, -> { where(status: 'completed') }
  scope :failed, -> { where(status: 'failed') }

  # Tidio-like execution tracking
  def mark_completed!
    update!(
      status: 'completed',
      completed_at: Time.current
    )
  end

  def mark_failed!(error_message = nil)
    update!(
      status: 'failed',
      error_message: error_message,
      completed_at: Time.current
    )
  end

  def cancel!
    update!(
      status: 'cancelled',
      completed_at: Time.current
    )
  end
end

