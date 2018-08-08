class CronWorkingRegularNotification
  include Sidekiq::Worker

  def perform
    # Working
    Intouch.send_notifications Issue.open.joins(:project).working.distinct, 'working'
  end
end
