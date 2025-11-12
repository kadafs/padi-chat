# frozen_string_literal: true

class EmailSenderJob < ApplicationJob
  queue_as :default

  def perform(app_user, email_data, context = {})
    return unless app_user&.email.present?

    # Prepare email content
    subject = email_data[:subject] || email_data['subject'] || 'Message from Chaskiq'
    content = email_data[:content] || email_data['content'] || ''
    template = email_data[:template] || email_data['template'] || 'default'

    # Send email using ActionMailer or your email service
    # This is a placeholder - you'd integrate with your actual email service
    ChaskiqMailer.send_email(
      to: app_user.email,
      subject: subject,
      body: content,
      template: template,
      context: context
    ).deliver_now

    # Log email sent
    Rails.logger.info "Email sent to #{app_user.email}: #{subject}"
  end
end


