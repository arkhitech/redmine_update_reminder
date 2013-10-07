Redmine::Plugin.register :task_reminder do
  name 'Task Reminder plugin'
  author 'Babar Rehman'
  description 'This is a plugin for Redmine which sends a reminder email to the assignee workign on a task, whose status is not updated with-in allowed duration'
  version '0.0.1'
  settings(:default => {'cc' => 'babar@rehman.com', 'header'=> 'do your work', 'footer'=>'seriously,do it already','duration'=>3}, :partial => 'reminder_settings')
end