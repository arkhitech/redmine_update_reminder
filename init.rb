Redmine::Plugin.register :redmine_update_reminder do
  name 'Redmine Update Reminder'
  author 'Arkhitech'
  url 'http://github.com/arkhitech/redmine_time_invoices'
  author_url 'https://github.com/arkhitech'
  description 'This is a plugin for Redmine which sends a reminder email to the assignee workign on a task, whose status is not updated with-in allowed duration'
  version '1.0.1'
  settings(default: {
             'header' => 'Update on Task Required',
             'footer' => 'powered by arkhitech.com',
             'duration' => 3
           }, partial: 'settings/reminder_settings')
end
