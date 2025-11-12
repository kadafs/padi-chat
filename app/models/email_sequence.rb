# frozen_string_literal: true

class EmailSequence < ApplicationRecord
  belongs_to :app
  has_many :email_sequence_steps, dependent: :destroy
  has_many :email_sequence_executions, dependent: :destroy

  validates :name, presence: true
  validates :trigger_event, inclusion: { 
    in: %w[signup purchase abandon_cart welcome feedback support], 
    allow_nil: true 
  }

  scope :active, -> { where(active: true) }
  scope :by_trigger, ->(event) { where(trigger_event: event) }

  # Tidio-like email sequence execution
  def execute_for_user(app_user, context = {})
    return unless active?

    # Create sequence execution record
    execution = EmailSequenceExecution.create!(
      email_sequence: self,
      app_user: app_user,
      context: context,
      status: 'started'
    )

    # Schedule first step
    first_step = email_sequence_steps.ordered.first
    if first_step
      schedule_step(first_step, app_user, execution, context)
    end

    execution
  end

  def duplicate!
    dup.tap do |new_sequence|
      new_sequence.name = "#{name} (Copy)"
      new_sequence.active = false
      new_sequence.save!
      
      # Duplicate steps
      email_sequence_steps.each do |step|
        new_sequence.email_sequence_steps.create!(
          step.attributes.except('id', 'email_sequence_id', 'created_at', 'updated_at')
        )
      end
    end
  end

  private

  def schedule_step(step, app_user, execution, context)
    delay_seconds = (step.delay_days * 24 * 3600) + (step.delay_hours * 3600)
    
    EmailSequenceStepJob.set(wait: delay_seconds.seconds)
                        .perform_later(
                          step.id,
                          app_user.id,
                          execution.id,
                          context
                        )
  end
end

