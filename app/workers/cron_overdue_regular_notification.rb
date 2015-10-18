class CronOverdueRegularNotification
  include Sidekiq::Worker

  def perform
    # Overdue and Without due date  (email only)
    overdue_issue_ids = Issue.open.joins(:project).where('due_date < ?', Date.today).pluck :id
    without_due_date_issue_ids = Issue.open.where(due_date: nil).where('created_on < ?', 1.day.ago)

    issue_ids = overdue_issue_ids + without_due_date_issue_ids

    Intouch.send_bulk_email_notifications Issue.open.where(id: issue_ids), 'overdue'

    # Overdue (telegram only)
    Intouch.send_notifications Issue.open.joins(:project).where('due_date < ?', Date.today), 'overdue'

    # Without due date (telegram only)
    Intouch.send_notifications Issue.open.where(due_date: nil).
                                      where('created_on < ?', 1.day.ago), 'overdue'
  end
end
