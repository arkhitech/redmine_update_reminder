def load_redmine_update_reminder_patches
  User.send(:include, RedmineUpdateReminder::Patches::UserPatch)
end

load_redmine_update_reminder_patches

Rails.configuration.to_prepare do
  load_redmine_update_reminder_patches
end

Redmine::Plugin.register :redmine_update_reminder do
  name 'Redmine Update Reminder'
  author 'Arkhitech'
  url 'https://github.com/arkhitech/redmine_update_reminder'
  author_url 'http://www.arkhitech.com'
  description 'This is a plugin for Redmine which sends a reminder email to the assignee working on a task, whose status is not updated with-in allowed duration'
  version '1.1'
  settings(default: {
             'header' => 'Missing Required Task Update',
             'footer' => 'powered by arkhitech.com',
           }, partial: 'settings/reminder_settings')
end