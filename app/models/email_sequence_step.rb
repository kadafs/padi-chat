# frozen_string_literal: true

class EmailSequenceStep < ApplicationRecord
  belongs_to :email_sequence

  validates :name, presence: true
  validates :step_order, presence: true, uniqueness: { scope: :email_sequence_id }

  scope :ordered, -> { order(:step_order) }
  scope :active, -> { where(active: true) }

  # Tidio-like email step execution
  def execute_for_user(app_user, execution, context = {})
    return unless active?

    # Send email
    EmailSenderJob.perform_later(
      app_user,
      {
        subject: subject_line,
        content: content,
        template: 'sequence_step'
      },
      context.merge(
        sequence_id: email_sequence.id,
        step_id: id,
        execution_id: execution.id
      )
    )

    # Schedule next step if exists
    next_step = email_sequence.email_sequence_steps
                              .where('step_order > ?', step_order)
                              .ordered
                              .first

    if next_step
      delay_seconds = (next_step.delay_days * 24 * 3600) + (next_step.delay_hours * 3600)
      
      EmailSequenceStepJob.set(wait: delay_seconds.seconds)
                          .perform_later(
                            next_step.id,
                            app_user.id,
                            execution.id,
                            context
                          )
    else
      # Sequence completed
      execution.update!(status: 'completed', completed_at: Time.current)
    end
  end
end


