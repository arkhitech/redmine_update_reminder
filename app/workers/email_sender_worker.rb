class EmailSenderWorker
  include Sidekiq::Worker

  def perform(issue_id)
    issue = Issue.find issue_id

    issue.intouch_recipients('email').each do |user|
      IntouchMailer.reminder_email(user, issue).deliver if user.present?
    end
  end
end
