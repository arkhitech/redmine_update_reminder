Redmine::Plugin.register :redmine_update_reminder do
  name 'Redmine Update Reminder'
  author 'Arkhitech'
  description 'This is a plugin for Redmine which sends a reminder email to the assignee workign on a task, whose status is not updated with-in allowed duration'
  version '0.0.1'
  settings(default: {
             'header' => 'Update on Task Required',
             'footer' => 'powered by arkhitech.com',
             'duration' => 3
           }, partial: 'settings/reminder_settings')
end
