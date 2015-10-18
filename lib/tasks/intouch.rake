namespace :intouch do
  namespace :telegram do
    # bundle exec rake intouch:telegram:bot PID_DIR='/tmp'
    desc "Runs telegram bot process (options: PID_DIR='/pid/dir')"
    task :bot => :environment do
      LOG = Logger.new(Rails.root.join('log', 'telegram-bot.log'))

      Process.daemon(true, true)

      if ENV['PID_DIR']
        pid_dir = ENV['PID_DIR']
        PidFile.new(piddir: pid_dir, pidfile: 'telegram-bot.pid')
      else
        PidFile.new(pidfile: 'telegram-bot.pid')
      end

      at_exit { LOG.error 'aborted by some reasons' }

      Signal.trap('TERM') do
        at_exit { LOG.error 'Aborted with TERM signal' }
        abort 'Aborted with TERM signal'
      end
      Signal.trap('QUIT') do
        at_exit { LOG.error 'Aborted with QUIT signal' }
        abort 'Aborted with QUIT signal'
      end
      Signal.trap('HUP') do
        at_exit { LOG.error 'Aborted with HUP signal' }
        abort 'Aborted with HUP signal'
      end

      LOG.info "Start daemon..."

      token = Setting.plugin_redmine_intouch['telegram_bot_token']

      unless token.present?
        LOG.error 'Telegram Bot Token not found. Please set it in the plugin config web-interface.'
        exit
      end

      LOG.info 'Telegram Bot: Connecting to telegram...'
      bot = Telegrammer::Bot.new(token)
      bot_name = bot.me.username

      until bot_name.present?

        LOG.error 'Telegram Bot Token is invalid or Telegram API is in downtime. I will try again after minute'
        sleep 60

        LOG.info 'Telegram Bot: Connecting to telegram...'
        bot = Telegrammer::Bot.new(token)
        bot_name = bot.me.username

      end

      LOG.info "#{bot_name}: connected"
      LOG.info "#{bot_name}: waiting for new users and group chats..."

      bot.get_updates(fail_silently: false) do |message|
        if message.text == '/start'
          user = message.from
          t_user = TelegramUser.where(tid: user.id).first_or_initialize(username: user.username,
                                                                        first_name: user.first_name,
                                                                        last_name: user.last_name)
          if t_user.new_record?
            t_user.save
            bot.send_message(chat_id: message.chat.id, text: "Hello, #{user.first_name}! I'm added your profile for Redmine notifications.")
            LOG.info "#{bot_name}: new user #{user.first_name} #{user.last_name} @#{user.username} added!"
          else
            reply.text = "Hello, #{user.first_name}! You are already connected for Redmine notifications."
            bot.send_message(reply)
          end
        elsif message.chat.id < 0
          chat = message.chat
          t_chat = TelegramGroupChat.where(tid: chat.id.abs).first_or_initialize(title: chat.title)
          if t_chat.new_record?
            t_chat.save
            bot.send_message(chat_id: message.chat.id, text: "Hello, people! I'm added this group chat for Redmine notifications.")
            LOG.info "#{bot_name}: new group #{chat.title} added!"
          else
          end
        end
      end
    end
  end
end
