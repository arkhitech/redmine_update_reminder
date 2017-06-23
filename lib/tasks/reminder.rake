namespace :redmine_update_reminder do
  task send_reminders: :environment do
    open_issue_status_ids = IssueStatus.where(is_closed: false).pluck('id')
    remind_group = Setting.plugin_redmine_update_reminder['remind_group']        
    user_ids = Group.includes(:users).find(remind_group).user_ids
    trackers = Tracker.all
    
    mailed_issue_ids = Set.new
    trackers.each do |t|
      update_duration = Setting.plugin_redmine_update_reminder["#{t.id}_update_duration"].to_f
      if update_duration > 0
        
        updated_since = Time.now - (update_duration.to_f * 24).hours
      	issues = Issue.where(tracker_id: t.id, assigned_to_id: user_ids, 
          status_id: open_issue_status_ids).where('updated_on < ?', updated_since)

        issues.find_each do |issue|       
          RemindingMailer.reminder_issue_email(issue.assigned_to, issue, update_duration).deliver
          mailed_issue_ids << issue.id
        end
      end      
    end
    open_issue_status_ids.each do |issue_status_id|
      update_duration = Setting.plugin_redmine_update_reminder["status-#{issue_status_id}_update_duration"].to_f      
      if update_duration > 0
        
        oldest_status_date = Time.now - (update_duration.to_f * 24).hours
      	issues = Issue.where(assigned_to_id: user_ids, status_id: issue_status_id).where.not(id: mailed_issue_ids.to_a)

        issues.find_each do |issue|       
          issue.history.history.each do |history_record|
            
            if history_record[:status_id] == issue_status_id
              if history_record[:date] && oldest_status_date > history_record[:date]
                RemindingMailer.reminder_status_email(issue.assigned_to, issue, update_duration).deliver
                mailed_issue_ids << issue.id
                break
              end
            end
            
          end
        end
      end      
    end
  end
end
