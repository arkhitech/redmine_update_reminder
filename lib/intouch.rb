module Intouch
  AVAILABLE_PROTOCOLS = %w(telegram email)
  INTOUCH_COMMIT_HASH = `cd #{Rails.root}/plugins/redmine_intouch && git rev-parse --short HEAD`.chomp

  def self.commit_hash
    INTOUCH_COMMIT_HASH
  end

  def self.active_protocols
    Setting.plugin_redmine_intouch['active_protocols'] || []
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

      if project.module_enabled?(:intouch) and project.active?
        reminder_settings = project.active_reminder_settings

        next unless reminder_settings.present?

        telegram_settings = project.active_telegram_settings

        project_issues.each do |issue|

          if issue.alarm? or Intouch.work_time?

            priority = issue.priority_id.to_s
            active = reminder_settings[priority].try(:[], 'active')
            interval = reminder_settings[priority].try(:[], 'interval')
            last_notification = issue.last_notification.try(:[], state)

            if active and
                interval.present? and
                issue.assigners_updated_on < interval.to_i.hours.ago and
                (last_notification.nil? or last_notification < interval.to_i.hours.ago)

              if active_protocols.include? 'email'
                IntouchSender.send_email_message(issue.id, state) unless %w(overdue without_due_date).include? state
              end

              if active_protocols.include? 'telegram'
                IntouchSender.send_telegram_message(issue.id, state)

                group_ids = telegram_settings.try(:[], state).try(:[], 'groups')
                IntouchSender.send_telegram_group_message(issue.id, group_ids) if group_ids.present?
              end

              issue.last_notification = {} unless issue.last_notification.present?
              issue.last_notification[state] = Time.now
            end
          end
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

        if project.module_enabled?(:intouch) and project.active?

          project_issues.each do |issue|

            user_ids = issue.recipient_ids('email', state)
            user_ids && user_ids.each do |user_id|
              user_issues_ids[user_id] = [] if user_issues_ids[user_id].nil?
              user_issues_ids[user_id] << issue.id
            end

          end
        end
      end

      user_issues_ids.each do |user_id, issue_ids|
        IntouchMailer.overdue_issues_email(user_id, issue_ids).deliver
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
    work_day? and from <= Time.now and Time.now <= to
  end

  def self.issue_url(issue_id)
    URI::HTTP.build({host: Setting['host_name'],  path: "/issues/#{issue_id}"}).to_s
  end

end
