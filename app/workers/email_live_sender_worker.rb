class EmailLiveSenderWorker
  include Sidekiq::Worker
  EMAIL_LIVE_SENDER_LOG = Logger.new(Rails.root.join('log/intouch', 'email-live-sender.log'))

  def perform(issue_id, journal_id, grouped_recipient_ids)
    Intouch.set_locale
    issue = Intouch::IssueDecorator.new(Issue.find(issue_id), journal_id, protocol: 'email')

    grouped_recipient_ids.each do |klass, ids|
      klass.constantize.where(id: ids).each do |user|
        IntouchMailer.reminder_email(user, issue).deliver
      end
    end
  rescue ActiveRecord::RecordNotFound => e
    EMAIL_LIVE_SENDER_LOG.error "#{e.class}: #{e.message}"
  end
end
