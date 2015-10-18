class CronEmailReminderSender
  include Sidekiq::Worker

  def perform
    if Intouch.work_time?

      trackers = Tracker.all

      trackers.each do |t|
        logger = Logger.new(Rails.root.join('log', 'intouch-email.log'))
        logger.info "Tracker: #{t.name}"

        open_issue_status_ids = IssueStatus.select('id').where(is_closed: false).collect { |is| is.id }

        update_duration = Setting.plugin_redmine_intouch["#{t.id}_update_duration"]
        if !update_duration.blank? && update_duration.to_f > 0
          updated_since = Time.now - (update_duration.to_f).hours
          issues = Issue.where('tracker_id = ? AND assigned_to_id IS NOT NULL AND status_id IN (?) AND (updated_on < ?)',
                               t.id, open_issue_status_ids, updated_since)

          issues.group_by(&:project_id).each do |project_id, project_issues|
            project = Project.find project_id
            if project.module_enabled?(:intouch) and project.active?
              project_issues.each do |issue|
                RemindingMailer.reminder_email(issue.assigned_to, issue).deliver if issue.assigned_to.present?
              end
            end
          end
        end
      end
    end

  end
end
