class TelegramSenderWorker
  include Sidekiq::Worker

  def perform(notice, project_id, issue_id)
    project = Project.find project_id
    issue = Issue.find issue_id

    template = if IntouchSetting[:settings_template_id, project_id].present?
       SettingsTemplate.find_by id: IntouchSetting[:settings_template_id, project_id]
    else
      nil
    end

    users = %w(author assigned_to watchers).map do |receiver|
      param = "telegram_#{notice}_#{receiver}"
      if template.present?
        receiver if template.settings[param].to_i > 0
      else
        receiver if IntouchSetting[param, project_id].to_i > 0
      end
    end.compact.map do |method|
      issue.send method
    end.flatten.uniq

    user_groups = if template.present?
                       template.settings["telegram_#{notice}_user_groups"]
                     else
                       IntouchSetting["telegram_#{notice}_user_groups", project_id]
                     end

    user_group_ids = user_groups.is_a?(Hash) ? user_groups.keys : []

    group_users = Group.where(id: user_group_ids).map(&:users).uniq

    receivers = (users + group_users).uniq

    message = "[#{issue.priority.try :name}] [#{issue.status.try :name}] #{project.name}: #{issue.subject} https://factory.southbridge.ru/issues/#{issue.id}"

    token = Setting.plugin_redmine_intouch['telegram_bot_token']
    bot = TelegramBot.new(token: token)

    receivers.each do |user|
      telegram_user = user.telegram_user
      next unless telegram_user.present?
      reply = TelegramBot::OutMessage.new(chat: TelegramBot::Channel.new(id: telegram_user.tid))
      reply.text = message
      bot.send_message(reply)
    end

    group_ids = IntouchSetting["telegram_#{notice}_telegram_groups".to_sym, project_id].keys

    TelegramGroupChat.where(id: group_ids).uniq.each do |group|
      reply = TelegramBot::OutMessage.new(chat: TelegramBot::Channel.new(id: -group.tid))
      reply.text = message
      bot.send_message(reply)
    end
  end

end
