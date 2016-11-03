class CronUnassignedRegularNotification
  include Sidekiq::Worker

  def perform
    # Unassigned
    Intouch.send_notifications Issue.open.joins(:project).where(assigned_to_id: nil), 'unassigned'

    # Assigned to Group
    Intouch.send_notifications Issue.open.joins(:project, :assigned_to).where(users: { type: 'Group' }), 'unassigned'
  end
end
