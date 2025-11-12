# frozen_string_literal: true

class EmailSequenceStepJob < ApplicationJob
  queue_as :default

  def perform(step_id, app_user_id, execution_id, context)
    step = EmailSequenceStep.find(step_id)
    app_user = AppUser.find(app_user_id)
    execution = EmailSequenceExecution.find(execution_id)

    return unless step && app_user && execution

    # Check if sequence is still active
    return unless step.email_sequence.active?

    # Execute the step
    step.execute_for_user(app_user, execution, context)
  end
end


