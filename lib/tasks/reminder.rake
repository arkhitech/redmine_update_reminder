namespace :redmine_update_reminder do

  def send_user_issue_estimates_reminders(issue_status_ids, user, mailed_issue_ids)
    issues_with_updated_since = []
    trackers = Tracker.all
    trackers.each do |tracker|
      issue_status_ids.each do |issue_status_id|
        estimate_update = Setting.plugin_redmine_update_reminder["#{tracker.id}-status-#{issue_status_id}-estimate"].to_f      

        if estimate_update > 0
          oldest_estimated_since = estimate_update.days.ago

          issues = Issue.where(tracker_id: tracker.id, assigned_to_id: user.id, status_id: issue_status_id).
            where('estimated_hours IS NULL OR estimated_hours <= 0').
            where.not(id: mailed_issue_ids.to_a)

          issues.each do |issue|
            if issue.updated_on < oldest_estimated_since
              issues_with_updated_since << [issue, issue.updated_on]
            end
          end
        end
      end
    end
    RemindingMailer.remind_user_issue_estimates(user, 
      issues_with_updated_since).deliver if issues_with_updated_since.count > 0
  end
  
  def send_user_past_due_issues_reminders(issue_status_ids, user, mailed_issue_ids)
    issues = Issue.where(assigned_to_id: user.id, 
      status_id: issue_status_ids).where('due_date < ?', Time.now).
      where.not(id: mailed_issue_ids.to_a)
    
    RemindingMailer.remind_user_past_due_issues(user, issues).deliver if issues.exists?
  end
  def send_user_tracker_reminders(issue_status_ids, user, mailed_issue_ids)
    trackers = Tracker.all
    issues_with_updated_since = []
    trackers.each do |tracker|
      update_duration = Setting.plugin_redmine_update_reminder["#{tracker.id}_update_duration"].to_f
      if update_duration > 0

        updated_since = update_duration.days.ago
        issues = Issue.where(tracker_id: tracker.id, assigned_to_id: user.id, status_id: issue_status_ids).
          where('updated_on < ?', updated_since).where.not(id: mailed_issue_ids.to_a)

        issues.find_each do |issue|
          issues_with_updated_since << [issue, issue.updated_on]
        end
      end      
    end    
    RemindingMailer.remind_user_issue_trackers(user, 
      issues_with_updated_since).deliver if issues_with_updated_since.count > 0
  end
  
  def send_user_status_reminders(issue_status_ids, user, mailed_issue_ids)
    issues_with_updated_since = []
    trackers = Tracker.all
    trackers.each do |tracker|
      issue_status_ids.each do |issue_status_id|
        update_duration = Setting.plugin_redmine_update_reminder["#{tracker.id}-status-#{issue_status_id}-update"].to_f      
        if update_duration > 0

          oldest_status_date = update_duration.days.ago
          issues = Issue.where(tracker_id: tracker.id, assigned_to_id: user.id, status_id: issue_status_id).
            where.not(id: mailed_issue_ids.to_a)

          issues.find_each do |issue|       
            issue.history.history.each do |history_record|

              if history_record[:status_id] == issue_status_id && 
                  history_record[:date] && oldest_status_date > history_record[:date]
                issues_with_updated_since << [issue, history_record[:date]]
                break
              end            
            end
          end
        end      
      end    
    end
    RemindingMailer.remind_user_issue_statuses(user, 
      issues_with_updated_since).deliver if issues_with_updated_since.count > 0    
  end  
  
  def send_issue_status_reminders(issue_status_ids, user_ids, mailed_issue_ids)
    Tracker.all.each do |tracker|
      issue_status_ids.each do |issue_status_id|
        update_duration = Setting.plugin_redmine_update_reminder["#{tracker.id}-status-#{issue_status_id}-update"].to_f      
        if update_duration > 0

          oldest_status_date = update_duration.days.ago
          issues = Issue.where(tracker_id: tracker.id, assigned_to_id: user_ids, status_id: issue_status_id).
            where.not(id: mailed_issue_ids.to_a)

          issues.find_each do |issue|       
            issue.history.history.each do |history_record|            
              if history_record[:status_id] == issue_status_id && 
                  history_record[:date] && oldest_status_date > history_record[:date]
                RemindingMailer.reminder_status_email(issue.assigned_to, issue, history_record[:date]).deliver
                mailed_issue_ids << issue.id
                break
              end            
            end
          end
        end      
      end    
    end
  end
  
  def send_issue_tracker_reminders(issue_status_ids, user_ids, mailed_issue_ids)
    trackers = Tracker.all
    
    trackers.each do |tracker|
      update_duration = Setting.plugin_redmine_update_reminder["#{tracker.id}_update_duration"].to_f
      if update_duration > 0
        
        updated_since = update_duration.days.ago
      	issues = Issue.where(tracker_id: tracker.id, assigned_to_id: user_ids, 
          status_id: issue_status_ids).where('updated_on < ?', updated_since).
          where.not(id: mailed_issue_ids.to_a)

        issues.find_each do |issue|       
          RemindingMailer.reminder_issue_email(issue.assigned_to, issue, issue.updated_on).deliver
          mailed_issue_ids << issue.id
        end
      end      
    end
    
  end
  
  task send_user_reminders: :environment do
    open_issue_status_ids = IssueStatus.where(is_closed: false).pluck('id')
    remind_group = Setting.plugin_redmine_update_reminder['remind_group']        
    users = Group.includes(:users).find(remind_group).users
    
    users.find_each do |user|
      mailed_issue_ids = Set.new
      send_user_tracker_reminders(open_issue_status_ids, user, mailed_issue_ids)
      send_user_status_reminders(open_issue_status_ids, user, mailed_issue_ids)
      send_user_past_due_issues_reminders(open_issue_status_ids, user, mailed_issue_ids)
      send_user_issue_estimates_reminders(open_issue_status_ids, user, mailed_issue_ids)
    end
  end
  
  task send_issue_reminders: :environment do    
    open_issue_status_ids = IssueStatus.where(is_closed: false).pluck('id')

    remind_group = Setting.plugin_redmine_update_reminder['remind_group']        
    user_ids = Group.includes(:users).find(remind_group).user_ids
    
    mailed_issue_ids = Set.new
    
    send_issue_tracker_reminders(open_issue_status_ids, user_ids, mailed_issue_ids)
    send_issue_status_reminders(open_issue_status_ids, user_ids, mailed_issue_ids)
  end
end
