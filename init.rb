require 'redmine'
require_dependency 'intouch'
require_dependency 'intouch/hook_listener'
require_dependency 'intouch/patches/projects_helper_patch'
require_dependency 'intouch/patches/project_patch'
require_dependency 'intouch/patches/issue_patch'
require_dependency 'intouch/patches/issue_priority_patch'
require_dependency 'intouch/patches/issue_status_patch'
require_dependency 'intouch/patches/user_patch'

Redmine::Plugin.register :redmine_intouch do
  name 'Redmine Intouch plugin'
  url 'https://github.com/olemskoi/redmine_intouch'
  description 'This is a plugin for Redmine which sends a reminder email and Telegram messages to the assignee workign on a task, whose status is not updated with-in allowed duration'
  version '0.0.3'
  author 'Centos-admin.ru'
  author_url 'http://centos-admin.ru'
  settings(partial: 'settings/intouch')

  project_module :intouch do
    permission :manage_intouch_settings, {
      :projects => :settings,
      :intouch_settings => :save,
    }
  end
end
