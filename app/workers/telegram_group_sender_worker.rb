class TelegramGroupSenderWorker
  include Sidekiq::Worker

  def perform(issue_id, group_ids)
    issue = Issue.find issue_id

    message = issue.telegram_message

    token = Setting.plugin_redmine_intouch['telegram_bot_token']
    bot = Telegrammer::Bot.new(token)

    TelegramGroupChat.where(id: group_ids).uniq.each do |group|
      next unless group.tid.present?
      bot.send_message(chat_id: -group.tid, text: message)
    end
  end
end
