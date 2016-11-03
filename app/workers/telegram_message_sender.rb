class TelegramMessageSender
  include Sidekiq::Worker
  sidekiq_options queue: :telegram,
                  rate: {
                    name: 'telegram_rate_limit',
                    limit: 15,
                    period: 1
                  }

  TELEGRAM_MESSAGE_SENDER_LOG = Logger.new(Rails.root.join('log/intouch', 'telegram-message-sender.log'))
  TELEGRAM_MESSAGE_SENDER_ERRORS_LOG = Logger.new(Rails.root.join('log/intouch', 'telegram-message-sender-errors.log'))

  def perform(telegram_user_id, message)
    token = Intouch.bot_token
    bot = Telegrammer::Bot.new(token)

    begin

      bot.send_message(chat_id: telegram_user_id, text: message, disable_web_page_preview: true, parse_mode: 'Markdown')
      TELEGRAM_MESSAGE_SENDER_LOG.info "telegram_user_id: #{telegram_user_id}\tmessage: #{message}"

    rescue Telegrammer::Errors::BadRequestError => e

      TELEGRAM_MESSAGE_SENDER_ERRORS_LOG.info "MESSAGE: #{message}"

      telegram_user = (telegram_user_id > 0) ?
        TelegramCommon::Account.find_by(tid: telegram_user_id) :
        TelegramGroupChat.find_by(tid: telegram_user_id.abs)

      if e.message.include? 'Bot was kicked'

        telegram_user.deactivate! if telegram_user.is_a? TelegramCommon::Account
        TELEGRAM_MESSAGE_SENDER_ERRORS_LOG.info "Bot was kicked from chat. Deactivate #{telegram_user.inspect}"

      elsif e.message.include? '429' or e.message.include? 'retry later'

        TELEGRAM_MESSAGE_SENDER_ERRORS_LOG.error "429 retry later error. retry to send after 5 seconds\ntelegram_user_id: #{telegram_user_id}\tmessage: #{message}"
        TelegramMessageSender.perform_in(5.seconds, telegram_user_id, message)

      else

        TELEGRAM_MESSAGE_SENDER_ERRORS_LOG.error "#{e.class}: #{e.message}"
        TELEGRAM_MESSAGE_SENDER_ERRORS_LOG.debug "#{telegram_user.inspect}"

      end

    rescue Telegrammer::Errors::ServiceUnavailableError

      TELEGRAM_MESSAGE_SENDER_ERRORS_LOG.error "ServiceUnavailableError. retry to send after 5 seconds\ntelegram_user_id: #{telegram_user_id}\tmessage: #{message}"
      TelegramMessageSender.perform_in(5.seconds, telegram_user_id, message)

    rescue 	Telegrammer::Errors::TimeoutError

      TELEGRAM_MESSAGE_SENDER_ERRORS_LOG.error "TimeoutError. retry to send after 5 seconds\ntelegram_user_id: #{telegram_user_id}\tmessage: #{message}"
      TelegramMessageSender.perform_in(5.seconds, telegram_user_id, message)

    end
  end

end
