module Intouch
  AVAILABLE_PROTOCOLS = %w(telegram email)

  def self.set_locale
    I18n.locale = Setting['default_language']
  end

  def self.bot_token
    Setting.plugin_redmine_intouch['telegram_bot_token']
  end

  def self.web_hook_url
    "https://#{Setting.host_name}/intouch/web_hook"
  end

  def self.sidekiq_cron_jobs
    names = %w(cron_overdue_regular_notification cron_working_regular_notification cron_unassigned_regular_notification cron_feedback_regular_notification)
    Sidekiq::Cron::Job.all.select { |job| names.include? job.name }
  end

  def self.active_protocols
    Setting.plugin_redmine_intouch['active_protocols'] || []
  end

  def self.handle_message(message)
    Intouch::TelegramBot.new(message).call if message.is_a?(Telegram::Bot::Types::Message)
  end

  def self.available_recipients
    if active_protocols.include? 'telegram'
      %w(author assigned_to watchers telegram_groups)
    else
      %w(author assigned_to watchers)
    end
  end

  def self.available_recipients_without(recipient)
    available_recipients - [recipient]
  end

  def self.send_notifications(issues, state)
    issues.group_by(&:project_id).each do |project_id, project_issues|
      project = Project.find_by id: project_id
      next unless project.present?

      next unless project.module_enabled?(:intouch) && project.active?
      reminder_settings = project.active_reminder_settings

      next unless reminder_settings.present?

      telegram_settings = project.active_telegram_settings

      project_issues.each do |issue|
        next unless issue.alarm? || Intouch.work_time?
        begin
          priority = issue.priority_id.to_s
          active = reminder_settings[priority].try(:[], 'active')
          interval = reminder_settings[priority].try(:[], 'interval')
          last_notification = issue.last_notification.try(:[], state)

          if active &&
             interval.present? &&
             Intouch::Regular::Message::Base.new(issue).latest_action_on < interval.to_i.hours.ago &&
             (last_notification.nil? || last_notification < interval.to_i.hours.ago)

            if active_protocols.include? 'email'
              IntouchSender.send_email_message(issue.id, state) unless %w(overdue without_due_date).include? state
            end

            if active_protocols.include? 'telegram'
              IntouchSender.send_telegram_message(issue.id, state)

              group_ids = telegram_settings.try(:[], state).try(:[], 'groups')
              IntouchSender.send_telegram_group_message(issue.id, group_ids, state) if group_ids.present?
            end

            last_notification = issue.last_notification
            last_notification = {} unless last_notification.present?
            last_notification[state] = Time.now
            issue.update_column :intouch_data, 'last_notification' => last_notification
          end
        rescue NoMethodError => e
          logger.error "#{e.class}: #{e.message}"
          logger.debug "State: #{state} Priority: #{priority} Active: #{active} Interval: #{interval} Last notification: #{last_notification}"
          logger.debug issue.inspect
          logger.debug project.inspect
        end
      end
    end
  end

  def self.send_bulk_email_notifications(issues, state)
    if Intouch.work_day?
      user_issues_ids = {}
      issues.group_by(&:project_id).each do |project_id, project_issues|
        project = Project.find_by id: project_id
        next unless project.present?

        next unless project.module_enabled?(:intouch) && project.active?

        project_issues.each do |issue|
          user_ids = issue.recipient_ids('email', state)
          user_ids && user_ids.each do |user_id|
            user_issues_ids[user_id] = [] if user_issues_ids[user_id].nil?
            user_issues_ids[user_id] << issue.id
          end
        end
      end

      user_issues_ids.each do |user_id, issue_ids|
        IntouchMailer.overdue_issues_email(user_id, issue_ids).deliver if user_id.present?
      end
    end
  end

  def self.work_day?
    settings = Setting.plugin_redmine_intouch
    work_days = settings.keys.select { |key| key.include?('work_days') }.map { |key| key.split('_').last.to_i }
    work_days.include? Date.today.wday
  end

  def self.work_time?
    from = Time.parse Setting.plugin_redmine_intouch['work_day_from']
    to = Time.parse Setting.plugin_redmine_intouch['work_day_to']
    work_day? && (from <= Time.now) && (Time.now <= to)
  end

  def self.issue_url(issue_id)
    "#{Setting['protocol']}://#{Setting['host_name']}/issues/#{issue_id}"
  end

  private

  def self.logger
    Logger.new(Rails.root.join('log/intouch', 'send-notifications.log'))
  end
end
