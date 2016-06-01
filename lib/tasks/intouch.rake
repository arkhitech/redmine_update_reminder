namespace :intouch do
  namespace :telegram do
    # bundle exec rake intouch:telegram:bot PID_DIR='/tmp'
    desc "Runs telegram bot process (options: PID_DIR='/pid/dir')"
    task :bot => :environment do
      tries = 0
      begin
        tries       += 1
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
          abort 'Aborted with TERM signal'
        end
        Signal.trap('QUIT') do
          at_exit { intouch_log.error 'Aborted with QUIT signal' }
          abort 'Aborted with QUIT signal'
        end
        Signal.trap('HUP') do
          at_exit { intouch_log.error 'Aborted with HUP signal' }
          abort 'Aborted with HUP signal'
        end

        intouch_log.info 'Start daemon...'

        token = Setting.plugin_redmine_intouch['telegram_bot_token']

        unless token.present?
          intouch_log.error 'Telegram Bot Token not found. Please set it in the plugin config web-interface.'
          exit
        end

        intouch_log.info 'Telegram Bot: Connecting to telegram...'
        bot      = Telegrammer::Bot.new(token)
        bot_name = bot.me.username

        until bot_name.present?

          intouch_log.error 'Telegram Bot Token is invalid or Telegram API is in downtime. I will try again after minute'
          sleep 60

          intouch_log.info 'Telegram Bot: Connecting to telegram...'
          bot      = Telegrammer::Bot.new(token)
          bot_name = bot.me.username

        end

        intouch_log.info "#{bot_name}: connected"
        intouch_log.info "#{bot_name}: waiting for new users and group chats..."

        bot.get_updates(fail_silently: false) do |message|
          begin
            next unless message.is_a?(Telegrammer::DataTypes::Message) # Update for telegrammer gem 0.8.0
            if message.text == '/start'
              user   = message.from
              t_user = TelegramUser.where(tid: user.id).first_or_initialize(username:   user.username,
                                                                            first_name: user.first_name,
                                                                            last_name:  user.last_name)
              if t_user.new_record?
                t_user.save
                bot.send_message(chat_id: message.chat.id, text: "Hello, #{user.first_name}! I've added your profile for Redmine notifications.")
                intouch_log.info "#{bot_name}: new user #{user.first_name} #{user.last_name} @#{user.username} added!"
              else
                t_user.update_columns username:   user.username,
                                      first_name: user.first_name,
                                      last_name:  user.last_name
                if t_user.active?
                  bot.send_message(chat_id: message.chat.id, text: "Hello, #{user.first_name}! I've updated your profile for Redmine notifications.")
                else
                  t_user.activate
                  bot.send_message(chat_id: message.chat.id, text: "Hello again, #{user.first_name}! I've activated your profile for Redmine notifications.")
                end
              end
            elsif message.text == '/update'
              user   = message.from
              t_user = TelegramUser.where(tid: user.id).first_or_create
              t_user.update_columns username:   user.username,
                                    first_name: user.first_name,
                                    last_name:  user.last_name

              bot.send_message(chat_id: message.chat.id, text: "Hello, #{user.first_name}! I've updated your profile for Redmine notifications.")
            elsif message.chat.id < 0
              chat   = message.chat
              t_chat = TelegramGroupChat.where(tid: chat.id.abs).first_or_initialize(title: chat.title)
              if t_chat.new_record?
                t_chat.save
                bot.send_message(chat_id: message.chat.id, text: "Hello, people! I'm added this group chat for Redmine notifications.")
                intouch_log.info "#{bot_name}: new group #{chat.title} added!"
              elsif message.text == '/rename'
                user = message.from
                t_chat.update title: chat.title
                bot.send_message(chat_id: message.chat.id, text: "Hello, #{user.first_name}! I'm updated this group chat title in Redmine.")
                intouch_log.info "#{bot_name}: rename group title #{chat.title}"
              end
            end
          rescue Exception => e
            intouch_log.error "#{e.class}: #{e.message}"
          end
        end

      rescue PidFile::DuplicateProcessError => e
        intouch_log.error "#{e.class}: #{e.message}"
        pid = e.message.match(/Process \(.+ - (\d+)\) is already running./)[1].to_i

        intouch_log.info "Kill process with pid: #{pid}"

        Process.kill('HUP', pid)
        if tries < 4
          intouch_log.info 'Waiting for 5 seconds...'
          sleep 5
          intouch_log.info 'Retry...'
          retry
        end
      rescue Exception => e
        intouch_log.error "#{e.class}: #{e.message}"
        if tries < 4
          sleep 2
          intouch_log.info "Retry after error. Try #{tries}"
          retry
        end
      end
    end
  end
end
