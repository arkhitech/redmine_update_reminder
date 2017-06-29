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
        PidFile.new(piddir: Rails.root.join('tmp', 'pids'), pidfile: 'telegram-bot.pid')
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

        require 'telegram/bot'

        bot = Telegram::Bot::Client.new(Intouch.bot_token)
        bot.api.setWebhook(url: '') # reset webhook
        bot.listen do |message|
          Intouch.handle_message(message)
        end

      rescue => e
        ExceptionNotifier.notify_exception(e) if defined?(ExceptionNotifier)
        intouch_log.error "GLOBAL ERROR #{e.class}: #{e.message}\n#{e.backtrace.join("\n")}"
      end
    end
  end
end
