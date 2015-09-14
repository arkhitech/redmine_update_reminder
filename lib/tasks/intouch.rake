namespace :intouch do
  namespace :email do

    desc "Send reminders to issue assignee which not updated for a long time"
    task :send_reminders => :environment do
      if work_day? and work_time?

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

            issues.each do |issue|
              RemindingMailer.reminder_email(issue.assigned_to, issue).deliver unless issue.assigned_to.nil?
            end
          end
        end
      end
    end
  end


  namespace :telegram do
    namespace :notification do
      desc 'Notification for telegram users about alarm issues'
      task :alarm => :environment do
        Issue.joins(:project).alarms.group_by(&:project_id).each do |project_id, issues|
          project = Project.find project_id
          if project.module_enabled?(:intouch)
            issues.each do |issue|
              TelegramSender.send_alarm_message(issue.project_id, issue.id) if issue.project.present?
            end
          end
        end
      end

      desc 'Notification for telegram users about new issues'
      task :new => :environment do
        if work_day? and work_time?
          Issue.joins(:project).news.group_by(&:project_id).each do |project_id, issues|
            project = Project.find project_id
            if project.module_enabled?(:intouch)
              issues.each do |issue|
                TelegramSender.send_new_message(issue.project_id, issue.id)
              end
            end
          end
        end
      end

      desc 'Notification for telegram users about overdue issues'
      task :overdue => :environment do
        if work_day? and work_time?
          Issue.joins(:project).where(status_id: IssueStatus.alarm_ids).where('due_date < ?', Date.today).
              where.not(priority_id: IssuePriority.alarm_ids).group_by(&:project_id).each do |project_id, issues|
            project = Project.find project_id
            if project.module_enabled?(:intouch)
              issues.each do |issue|
                TelegramSender.send_overdue_message(issue.project_id, issue.id)
              end
            end
          end
        end
      end

      desc 'Notification for telegram users about working issues'
      task :work_in_progress => :environment do
        if work_day? and work_time?
          Issue.joins(:project).working.group_by(&:project_id).each do |project_id, issues|
            project = Project.find project_id
            if project.module_enabled?(:intouch)
              issues.each do |issue|
                TelegramSender.send_working_message(issue.project_id, issue.id) if issue.updated_on < 2.hours.ago
              end
            end
          end
        end
      end

      desc 'Notification for telegram users about feedback issues'
      task :feedback => :environment do
        if work_day? and work_time?
          Issue.joins(:project).feedbacks.group_by(&:project_id).each do |project_id, issues|
            project = Project.find project_id
            if project.module_enabled?(:intouch)
              issues.each do |issue|
                TelegramSender.send_feedback_message(issue.project_id, issue.id) if issue.updated_on < 2.hours.ago
              end
            end
          end
        end
      end
    end

    # bundle exec rake intouch:telegram:bot PID_DIR='/tmp'
    desc "Runs telegram bot process (options: PID_DIR='/pid/dir')"
    task :bot => :environment do
      logger = Logger.new(Rails.root.join('log', 'telegram-bot.log'))

      Process.daemon(true, true)

      if ENV['PID_DIR']
        pid_dir = ENV['PID_DIR']
        PidFile.new(piddir: pid_dir, pidfile: 'telegram-bot.pid')
      end

      Signal.trap('TERM') { abort }
      Signal.trap('QUIT') { abort }
      Signal.trap('HUP') { abort }

      logger.info "Start daemon..."

      token = Setting.plugin_redmine_intouch['telegram_bot_token']

      unless token.present?
        logger.error 'Telegram Bot Token not found. Please set it in the plugin config web-interface.'
        exit
      end

      logger.info 'Telegram Bot: Connecting to telegram...'
      bot = TelegramBot.new(token: token)
      bot_name = bot.get_me.username

      unless bot_name.present?
        logger.error 'Telegram Bot Token is invalid'
        exit
      end

      logger.info "#{bot_name}: connected"
      logger.info "#{bot_name}: waiting for new users and group chats..."

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
            logger.info "#{bot_name}: new user #{user.first_name} #{user.last_name} @#{user.username} added!"
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
            logger.info "#{bot_name}: new group #{chat.title} added!"
          else
            # reply.text = 'Hello, again!'
            # bot.send_message(reply)
          end
        end
      end
    end
  end
end


def work_day?
  settings = Setting.plugin_redmine_intouch
  work_days = settings.keys.select { |key| key.include?('work_days') }.map { |key| key.split('_').last.to_i }
  work_days.include? Date.today.wday
end

def work_time?
  from = Time.parse Setting.plugin_redmine_intouch['work_day_from']
  to = Time.parse Setting.plugin_redmine_intouch['work_day_to']
  from <= Time.now and Time.now <= to
end
