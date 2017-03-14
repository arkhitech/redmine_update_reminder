class EmailLiveSenderWorker
  include Sidekiq::Worker
  EMAIL_LIVE_SENDER_LOG = Logger.new(Rails.root.join('log/intouch', 'email-live-sender.log'))

  def perform(issue_id, _required_recipients = [])
    Intouch.set_locale
    issue = Issue.find issue_id

    issue.intouch_live_recipients('email').each do |user|
      IntouchMailer.reminder_email(user, issue).deliver if user.present?
    end
  rescue ActiveRecord::RecordNotFound => e
    EMAIL_LIVE_SENDER_LOG.error "#{e.class}: #{e.message}"
  end
end
