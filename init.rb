require 'redmine'
require_dependency 'intouch_hook_listener'
require_dependency 'intouch/user_patch'

Redmine::Plugin.register :redmine_intouch do
  name 'Redmine Intouch plugin'
  url 'https://github.com/olemskoi/redmine_intouch'
  description 'This is a plugin for Redmine which sends a reminder email and Telegram messages to the assignee workign on a task, whose status is not updated with-in allowed duration'
  version '0.0.1'
  author 'Centos-admin.ru'
  author_url 'http://centos-admin.ru'
  settings(default: {
               'header' => 'Update on Task Required',
               'footer' => 'powered by Centos-admin.ru',
               'duration' => 3
           }, partial: 'settings/reminder_settings')
end
