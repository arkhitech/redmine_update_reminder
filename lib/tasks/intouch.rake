namespace :intouch do
  namespace :common do
    # bundle exec rake intouch:common:migrate
    task migrate: :environment do
      TelegramUser.find_each do |telegram_user|
        TelegramCommon::Account.where(telegram_id: telegram_user.tid)
          .first_or_create(telegram_user.slice(:user_id, :first_name, :last_name, :username, :active))
      end
    end
  end

  namespace :telegram do
    # bundle exec rake intouch:telegram:bot PID_DIR='tmp/pids'
    desc "Runs telegram bot process (options: PID_DIR='tmp/pids')"
    task bot: :environment do
      intouch_log = Rails.env.production? ? Logger.new(Rails.root.join('log/intouch', 'telegram-bot.log')) : Logger.new(STDOUT)

      Process.daemon(true, true) if Rails.env.production?

      if ENV['PID_DIR']
        pid_dir = ENV['PID_DIR']
        PidFile.new(piddir: pid_dir, pidfile: 'telegram-bot.pid')
      else
        PidFile.new(pidfile: 'telegram-bot.pid')
      end

      Signal.trap('TERM') do
        at_exit { intouch_log.error 'Aborted with TERM signal' }
        abort
      end

      intouch_log.info 'Start daemon...'

      begin
        token = Intouch.bot_token

        unless token.present?
          intouch_log.error 'Telegram Bot Token not found. Please set it in the plugin config web-interface.'
          exit
        end

        intouch_log.info 'Telegram Bot: Connecting to telegram...'
        bot = Telegrammer::Bot.new(token)
        bot.set_webhook('') # reset webhook
        bot_name = bot.me.username

        intouch_log.info "#{bot_name}: connected"
        intouch_log.info "#{bot_name}: waiting for new users and group chats..."

        bot.get_updates(fail_silently: false) do |message|
          begin
            next unless message.is_a?(Telegrammer::DataTypes::Message)
            Intouch::TelegramBot.new(message).call
          rescue Exception => e
            ExceptionNotifier.notify_exception(e) if defined?(ExceptionNotifier)
            intouch_log.error "UPDATE ERROR #{e.class}: #{e.message}\n#{e.backtrace.join("\n")}"
          end
        end

      rescue HTTPClient::ConnectTimeoutError, HTTPClient::KeepAliveDisconnected,
             Telegrammer::Errors::TimeoutError, Telegrammer::Errors::ServiceUnavailableError => e
        intouch_log.error "GLOBAL ERROR WITH RESTART #{e.class}: #{e.message}\n#{e.backtrace.join("\n")}"
        intouch_log.info 'Restarting...'
        retry

      rescue Exception => e
        ExceptionNotifier.notify_exception(e) if defined?(ExceptionNotifier)
        intouch_log.error "GLOBAL ERROR #{e.class}: #{e.message}\n#{e.backtrace.join("\n")}"
      end
    end
  end
end
