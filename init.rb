require 'redmine'
require_dependency 'intouch_hook_listener'
require_dependency 'intouch/user_patch'

Redmine::Plugin.register :redmine_intouch do
  name 'Redmine Intouch plugin'
  author 'Artur Trofimov'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'https://github.com/arturtr/redmine_intouch'
  author_url 'https://github.com/arturtr'
  description 'This is a plugin for Redmine which sends a reminder email and Telegram messages to the assignee workign on a task, whose status is not updated with-in allowed duration'
  settings(default: {
               'header' => 'Update on Task Required',
               'footer' => 'powered by arkhitech.com',
               'duration' => 3
           }, partial: 'settings/reminder_settings')
end
