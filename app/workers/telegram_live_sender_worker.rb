class TelegramLiveSenderWorker
  include Sidekiq::Worker
  TELEGRAM_LIVE_SENDER_LOG = Logger.new(Rails.root.join('log', 'telegram-live-sender.log'))

  def perform(issue_id)
    issue = Issue.find issue_id

    message = issue.telegram_live_message

    token = Setting.plugin_redmine_intouch['telegram_bot_token']
    bot = Telegrammer::Bot.new(token)

    issue.intouch_live_recipients('telegram').each do |user|
      message = if issue.assigned_to_id == user.id
                  "#{message}\n(Исполнителю)"
                elsif issue.author_id == user.id
                  "#{message}\n(Автору)"
                elsif issue.watchers.pluck(:user_id).include? user.id
                  "#{message}\n(Наблюдателю)"
                end

      telegram_user = user.telegram_user
      next unless telegram_user.present?
      begin
        bot.send_message(chat_id: telegram_user.tid, text: message, disable_web_page_preview: true)
      rescue Telegrammer::Errors::BadRequestError => e
        TELEGRAM_LIVE_SENDER_LOG.error "#{e.class}: #{e.message}"
        TELEGRAM_LIVE_SENDER_LOG.debug "#{issue.inspect}"
        TELEGRAM_LIVE_SENDER_LOG.debug "#{user.inspect}"
        TELEGRAM_LIVE_SENDER_LOG.debug "#{telegram_user.inspect}"
      end
    end
  end

end
