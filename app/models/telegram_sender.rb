class TelegramSender
  def self.send_alarm_message(project_id, issue_id)
    project = Project.find project_id
    issue = project.issues.find issue_id

    notice = 'alarm'
    project_id = 1

    users = %w(author assigned_to watchers).map do |receiver|
      param = "telegram_#{notice}_#{receiver}".to_sym
      receiver if IntouchSetting[param, project_id].to_i > 0
    end.compact.map do |method|
      issue.send method
    end.flatten.uniq

    message = "ALARM!!! #{project.name}: #{issue.subject}"
    token = Setting.plugin_redmine_intouch['telegram_bot_token']
    bot = TelegramBot.new(token: token)

    users.each do |user|
      telegram_user = user.telegram_user
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
