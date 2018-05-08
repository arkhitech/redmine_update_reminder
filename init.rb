require_dependency Rails.root.join('plugins','redmine_telegram_common', 'init')

FileUtils.mkdir_p(Rails.root.join('log/intouch')) unless Dir.exist?(Rails.root.join('log/intouch'))

require 'intouch'
require 'telegram/bot'

# Rails 5.1/Rails 4
reloader = defined?(ActiveSupport::Reloader) ? ActiveSupport::Reloader : ActionDispatch::Reloader
reloader.to_prepare do
  paths = '/lib/intouch/{patches/*_patch,hooks/*_hook}.rb'
  Dir.glob(File.dirname(__FILE__) + paths).each do |file|
    require_dependency file
  end

  require_dependency 'redmine_bots'
  RedmineBots::Telegram.update_manager.add_handler(->(message) { Intouch.handle_message(message) } )
end

Rails.application.config.eager_load_paths += Dir.glob("#{Rails.application.config.root}/plugins/redmine_intouch/{lib,app/workers,app/models,app/controllers}")

Intouch.register_protocol('telegram', Intouch::Protocols::Telegram.new)
Intouch.register_protocol('slack', Intouch::Protocols::Slack.new)
Intouch.register_protocol('email', Intouch::Protocols::Email.new)


Redmine::Plugin.register :redmine_intouch do
  name 'Redmine Intouch plugin'
  url 'https://github.com/centosadmin/redmine_intouch'
  description 'This is a plugin for Redmine which sends a reminder email and Telegram messages to the assignee workign on a task, whose status is not updated with-in allowed duration'
  version '1.2.1'
  author 'Southbridge'
  author_url 'https://github.com/centosadmin'

  requires_redmine version_or_higher: '3.0'

  # requires_redmine_plugin :redmine_telegram_common, '0.7.0'

  settings(
    default: {
      'active_protocols' => %w(email),
      'work_day_from' => '10:00',
      'work_day_to' => '18:00'
    },
    partial: 'settings/intouch')

  project_module :intouch do
    permission :manage_intouch_settings,
      projects: :settings,
      intouch_settings: :save
  end
end
