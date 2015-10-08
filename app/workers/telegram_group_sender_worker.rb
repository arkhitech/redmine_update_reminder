class TelegramGroupSenderWorker
  include Sidekiq::Worker

  def perform(issue_id, group_ids)
    issue = Issue.find issue_id

    message = issue.telegram_message

    token = Setting.plugin_redmine_intouch['telegram_bot_token']
    bot = TelegramBot.new(token: token)

    TelegramGroupChat.where(id: group_ids).uniq.each do |group|
      next unless group.tid.present?
      reply = TelegramBot::OutMessage.new(chat: TelegramBot::Channel.new(id: -group.tid))
      reply.text = message
      bot.send_message(reply)
    end
  end
end
