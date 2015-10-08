class TelegramSenderWorker
  include Sidekiq::Worker

  def perform(issue_id)
    issue = Issue.find issue_id

    message = issue.telegram_message

    token = Setting.plugin_redmine_intouch['telegram_bot_token']
    bot = TelegramBot.new(token: token)

    issue.intouch_recipients('telegram').each do |user|
      telegram_user = user.telegram_user
      next unless telegram_user.present?
      reply = TelegramBot::OutMessage.new(chat: TelegramBot::Channel.new(id: telegram_user.tid))
      reply.text = message
      bot.send_message(reply)
    end
  end

end
