class EmailSenderWorker
  include Sidekiq::Worker
  EMAIL_SENDER_LOG = Logger.new(Rails.root.join('log/intouch', 'email-sender.log'))

  def perform(issue_id, state)
    Intouch.set_locale
    issue = Issue.find issue_id

    issue.intouch_recipients('email', state).each do |user|
      IntouchMailer.reminder_email(user, issue).deliver if user.present?
    end
  rescue ActiveRecord::RecordNotFound => e
    EMAIL_SENDER_LOG.error "#{e.class}: #{e.message}"
  end
end
