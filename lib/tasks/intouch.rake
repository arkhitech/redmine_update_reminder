namespace :intouch do
  namespace :email do
    task :send_reminders => :environment do
      trackers = Tracker.all

      trackers.each do |t|
        logger = Rails.logger
        logger.info "Tracker:#{t.name}"

        open_issue_status_ids = IssueStatus.select('id').where(is_closed: false).collect { |is| is.id }

        update_duration = Setting.plugin_redmine_update_reminder["#{t.id}_update_duration"]
        if !update_duration.blank? && update_duration.to_f > 0
          updated_since = Time.now - (update_duration.to_f * 24).hours
          issues = Issue.where('tracker_id = ? AND assigned_to_id IS NOT NULL AND status_id IN (?) AND (updated_on < ?)',
                               t.id, open_issue_status_ids, updated_since)

          issues.each do |issue|
            RemindingMailer.reminder_email(issue.assigned_to, issue).deliver unless issue.assigned_to.nil?
          end
        end
      end
    end
  end


  namespace :telegram do
    namespace :notification do
      task :alarm do
        alarm_priority_ids = IssuePriority.alarm_ids

      end

      task :new do

      end

      task :work_in_progress do

      end
    end

    task :bot => :environment do
      token = Setting.plugin_redmine_intouch['telegram_bot_token']

      unless token.present?
        puts 'Telegram Bot Token not found. Please set it in the plugin config web-interface.'
        exit
      end

      puts 'Telegram Bot: Connecting to telegram...'
      bot = TelegramBot.new(token: token)
      bot_name = bot.get_me.username

      unless bot_name.present?
        puts 'Telegram Bot Token is invalid'
        exit
      end

      puts "#{bot_name}: connected"
      puts "#{bot_name}: waiting for new users and group chats..."

      bot.get_updates(fail_silently: true) do |message|
        if message.text == '/start'
          # create telegram user
          user = message.user
          t_user = TelegramUser.where(tid: user.id).first_or_initialize(username: user.username,
                                                                        first_name: user.first_name,
                                                                        last_name: user.last_name)
          reply = message.reply
          if t_user.new_record?
            t_user.save
            reply.text = "Hello, #{user.first_name}! I'm added your profile for RedMine notifications."
            bot.send_message(reply)
            puts "#{bot_name}: new user #{user.username} added!"
          else
            reply.text = "Hello, #{user.first_name}! You are already connected for RedMine notifications."
            bot.send_message(reply)
          end
        elsif message.chat.id < 0
          # create telegram group
          chat = message.chat
          t_chat = TelegramGroupChat.where(tid: chat.id.abs).first_or_initialize(title: chat.title)
          reply = message.reply
          if t_chat.new_record?
            t_chat.save
            reply.text = "Hello, people! I'm added this group chat for RedMine notifications."
            bot.send_message(reply)
            puts "#{bot_name}: new group #{chat.title} added!"
          else
            reply.text = 'Hello, again!'
            bot.send_message(reply)
          end
        end
      end
    end
  end
end
