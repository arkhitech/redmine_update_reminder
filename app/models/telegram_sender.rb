class TelegramSender
  unloadable

  def self.send_alarm_message(project_id, issue_id)
    send_message('alarm', project_id, issue_id)
  end

  def self.send_new_message(project_id, issue_id)
    send_message('new', project_id, issue_id)
  end

  def self.send_working_message(project_id, issue_id)
    send_message('working', project_id, issue_id)
  end

  def self.send_feedback_message(project_id, issue_id)
    send_message('feedback', project_id, issue_id)
  end

  def self.send_message(notice, project_id, issue)
    project = Project.find project_id

    users = %w(author assigned_to watchers).map do |receiver|
      param = "telegram_#{notice}_#{receiver}".to_sym
      receiver if IntouchSetting[param, project_id].to_i > 0
    end.compact.map do |method|
      issue.send method
    end.flatten.uniq

    user_group_ids = IntouchSetting["telegram_#{notice}_user_groups".to_sym, project_id].keys

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
