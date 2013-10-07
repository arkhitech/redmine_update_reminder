task :trackers => :environment do
trackers=Tracker.all
trackers.each do |t|
  puts "Tracker:#{t.name}"
    
    open_issue_status_ids = IssueStatus.select('id').where(is_closed: false).collect { |u| u.id}
    issues = Issue.where(['tracker_id = ? AND assigned_to_id IS NOT NULL AND status_id IN (?) AND (updated_on <?)',t.id, open_issue_status_ids, Time.now-(Setting.plugin_task_reminder["#{t.id}_update_duration"].to_f*24).hours])
    issues.each do |i|
        user = User.where(['id = ? AND mail IS NOT NULL', i.assigned_to_id])
        user=user[0]
        puts "Subject: #{i.subject}"
        puts "To: #{user.name}: #{user.mail}"
        
       
        RemindingMailer.reminder_email(user,i).deliver
        
      end
    end
  end