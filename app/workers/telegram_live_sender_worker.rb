class TelegramLiveSenderWorker
  include Sidekiq::Worker
  TELEGRAM_LIVE_SENDER_LOG = Logger.new(Rails.root.join('log/intouch', 'telegram-live-sender.log'))

  def perform(issue_id)
    issue = Issue.find issue_id

    message = issue.telegram_live_message

    token = Setting.plugin_redmine_intouch['telegram_bot_token']
    bot = Telegrammer::Bot.new(token)

    issue.intouch_live_recipients('telegram').each do |user|

      telegram_user = user.telegram_user
      next unless telegram_user.present?

      message = if issue.assigned_to_id == user.id
                  "Исполнителю\n#{message}"
                elsif issue.author_id == user.id
                  "Автору\n#{message}"
                elsif issue.watchers.pluck(:user_id).include? user.id
                  "Наблюдателю\n#{message}"
                else
                  message
                end

      begin
        bot.send_message(chat_id: telegram_user.tid, text: message, disable_web_page_preview: true)
      rescue Telegrammer::Errors::BadRequestError => e
        TELEGRAM_LIVE_SENDER_LOG.error "#{e.class}: #{e.message}"
        TELEGRAM_LIVE_SENDER_LOG.debug "#{issue.inspect}"
        TELEGRAM_LIVE_SENDER_LOG.debug "#{user.inspect}"
        TELEGRAM_LIVE_SENDER_LOG.debug "#{telegram_user.inspect}"
      end
    end
  rescue ActiveRecord::RecordNotFound => e
    TELEGRAM_LIVE_SENDER_LOG.error "#{e.class}: #{e.message}"
  end

end
