class CronFeedbackRegularNotification
  include Sidekiq::Worker

  def perform
    # Feedback
    Intouch.send_notifications Issue.open.joins(:project).feedbacks.distinct, 'feedback'
  end
end
