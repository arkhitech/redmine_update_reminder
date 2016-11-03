class CronOverdueRegularNotification
  include Sidekiq::Worker

  def perform
    if Intouch.active_protocols.include? 'email'
      # Overdue and Without due date  (email only)
      overdue_issue_ids = Issue.open.joins(:project).where('due_date < ?', Date.today).pluck :id
      without_due_date_issue_ids = Issue.open.where(due_date: nil).where('created_on < ?', 1.day.ago).pluck :id

      unassigned_issue_ids = Issue.open.joins(:project).where(assigned_to_id: nil).pluck :id
      group_assigned_issue_ids = Issue.open.joins(:project, :assigned_to).where(users: { type: 'Group' }).pluck :id

      issue_ids = overdue_issue_ids + without_due_date_issue_ids + unassigned_issue_ids + group_assigned_issue_ids

      Intouch.send_bulk_email_notifications Issue.open.where(id: issue_ids), 'overdue'
    end

    if Intouch.active_protocols.include? 'telegram'
      # Overdue (telegram only)
      Intouch.send_notifications Issue.open.joins(:project).where('due_date < ?', Date.today), 'overdue'

      # Without due date (telegram only)
      Intouch.send_notifications Issue.open.where(due_date: nil)
                                     .where('created_on < ?', 1.day.ago), 'overdue'
    end
  end
end
