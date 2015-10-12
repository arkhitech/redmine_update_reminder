namespace :intouch do
  namespace :regular_notification do
    desc 'Notification  about alarm issues'
    task :alarm => :environment do
      Issue.joins(:project).alarms.group_by(&:project_id).each do |project_id, issues|
        project = Project.find project_id
        if project.module_enabled?(:intouch) and project.active?
          issues.each do |issue|
            IntouchSender.send_telegram_message(issue.id)
            IntouchSender.send_email_message(issue.id)
          end
        end
      end
    end

    desc 'Notification  about new issues'
    task :new => :environment do
      if Intouch.work_day?
        Issue.joins(:project).news.group_by(&:project_id).each do |project_id, issues|
          project = Project.find project_id
          if project.module_enabled?(:intouch) and project.active?
            issues.each do |issue|
              IntouchSender.send_telegram_message(issue.id)
              IntouchSender.send_email_message(issue.id)
            end
          end
        end
      end
    end

    desc 'Notification  about overdue issues'
    task :overdue => :environment do
      if Intouch.work_day?
        Issue.joins(:project).where(status_id: IssueStatus.alarm_ids).where('due_date < ?', Date.today).
            where.not(priority_id: IssuePriority.alarm_ids).group_by(&:project_id).each do |project_id, issues|
          project = Project.find project_id
          if project.module_enabled?(:intouch) and project.active?
            issues.each do |issue|
              IntouchSender.send_telegram_message(issue.id)
              IntouchSender.send_email_message(issue.id)
            end
          end
        end
      end
    end

    desc 'Notification  about working issues'
    task :work_in_progress => :environment do
      if Intouch.work_time?
        Issue.joins(:project).working.group_by(&:project_id).each do |project_id, issues|
          project = Project.find project_id
          if project.module_enabled?(:intouch) and project.active?
            issues.each do |issue|
              if issue.updated_on < 2.hours.ago
                IntouchSender.send_telegram_message(issue.id)
                IntouchSender.send_email_message(issue.id)
              end
            end
          end
        end
      end
    end

    desc 'Notification  about feedback issues'
    task :feedback => :environment do
      if Intouch.work_time?
        Issue.joins(:project).feedbacks.group_by(&:project_id).each do |project_id, issues|
          project = Project.find project_id
          if project.module_enabled?(:intouch) and project.active?
            issues.each do |issue|
              if issue.updated_on < 2.hours.ago
                IntouchSender.send_telegram_message(issue.id)
                IntouchSender.send_email_message(issue.id)
              end
            end
          end
        end
      end
    end
  end

  namespace :email do

    desc "Send reminders to issue assignee which not updated for a long time"
    task :send_reminders => :environment do
      if Intouch.work_time?

        trackers = Tracker.all

        trackers.each do |t|
          logger = Logger.new(Rails.root.join('log', 'intouch-email.log'))
          logger.info "Tracker: #{t.name}"

          open_issue_status_ids = IssueStatus.select('id').where(is_closed: false).collect { |is| is.id }

          update_duration = Setting.plugin_redmine_intouch["#{t.id}_update_duration"]
          if !update_duration.blank? && update_duration.to_f > 0
            updated_since = Time.now - (update_duration.to_f).hours
            issues = Issue.where('tracker_id = ? AND assigned_to_id IS NOT NULL AND status_id IN (?) AND (updated_on < ?)',
                                 t.id, open_issue_status_ids, updated_since)

            issues.group_by(&:project_id).each do |project_id, project_issues|
              project = Project.find project_id
              if project.module_enabled?(:intouch) and project.active?
                project_issues.each do |issue|
                  RemindingMailer.reminder_email(issue.assigned_to, issue).deliver if issue.assigned_to.present?
                end
              end
            end
          end
        end
      end
    end
  end


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
      bot = TelegramBot.new(token: token, logger: LOG)
      bot_name = bot.get_me.username

      until bot_name.present?

        LOG.error 'Telegram Bot Token is invalid or Telegram API is in downtime. I will try again after minute'
        sleep 60

        LOG.info 'Telegram Bot: Connecting to telegram...'
        bot = TelegramBot.new(token: token, logger: LOG)
        bot_name = bot.get_me.username

      end

      LOG.info "#{bot_name}: connected"
      LOG.info "#{bot_name}: waiting for new users and group chats..."

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
            reply.text = "Hello, #{user.first_name}! I'm added your profile for Redmine notifications."
            bot.send_message(reply)
            LOG.info "#{bot_name}: new user #{user.first_name} #{user.last_name} @#{user.username} added!"
          else
            reply.text = "Hello, #{user.first_name}! You are already connected for Redmine notifications."
            bot.send_message(reply)
          end
        elsif message.chat.id < 0
          # create telegram group
          chat = message.chat
          t_chat = TelegramGroupChat.where(tid: chat.id.abs).first_or_initialize(title: chat.title)
          reply = message.reply
          if t_chat.new_record?
            t_chat.save
            reply.text = "Hello, people! I'm added this group chat for Redmine notifications."
            bot.send_message(reply)
            LOG.info "#{bot_name}: new group #{chat.title} added!"
          else
            # reply.text = 'Hello, again!'
            # bot.send_message(reply)
          end
        end
      end
    end
  end
end
