module Intouch
  module IssuePatch
    def self.included(base) # :nodoc:
      base.class_eval do
        unloadable if Rails.env.production?

        before_save :check_alarm
        after_create :send_new_message

        def self.alarms
          Issue.where(priority_id: IssuePriority.alarm_ids, status_id: IssueStatus.alarm_ids)
        end

        def self.news
          Issue.where(status_id: IssueStatus.new_ids).where.not(priority_id: IssuePriority.alarm_ids)
        end

        def self.working
          Issue.where(status_id: IssueStatus.working_ids).where.not(priority_id: IssuePriority.alarm_ids)
        end

        def self.feedbacks
          Issue.where(status_id: IssueStatus.feedback_ids).where.not(priority_id: IssuePriority.alarm_ids)
        end

        def alarm?
          IssuePriority.alarm_ids.include? priority_id
        end

        def new?
          IssueStatus.new_ids.include? status_id and not alarm?
        end

        def working?
          IssueStatus.working_ids.include? status_id and not alarm?
        end

        def feedback?
          IssueStatus.feedback_ids.include? status_id and not alarm?
        end

        def overdue?
          due_date && due_date < Date.today
        end

        def without_due_date?
          !due_date.present? and created_at < 1.day.ago
        end

        def notification_status
          %w(alarm new working feedback overdue).select { |s| send("#{s}?") }.try :first
        end

        def recipient_ids(protocol)
          if notification_status
            project.send("active_#{protocol}_settings")[notification_status].map do |key, value|
              case key
                when 'author'
                  author.id
                when 'assigned_to'
                  assigned_to.id
                when 'watchers'
                  watchers.pluck(:user_id)
                when 'user_groups'
                  Group.where(id: value.try(:keys)).map(&:users).flatten.map(&:id)
                else
                  nil
              end
            end.flatten.uniq
          end
        end

        def live_recipient_ids(protocol)
          recipients = project.send("active_#{protocol}_settings").select { |k, v| %w(author assigned_to watchers user_groups).include? k }

          user_ids = []
          recipients.each_pair do |key, value|
            case key
              when 'author'
                user_ids << author.id if value.try(:[], status_id.to_s).try(:include?, priority_id.to_s)
              when 'assigned_to'
                user_ids << assigned_to.id if value.try(:[], status_id.to_s).try(:include?, priority_id.to_s)
              when 'watchers'
                user_ids << watchers.pluck(:user_id) if value.try(:[], status_id.to_s).try(:include?, priority_id.to_s)
              when 'user_groups'
                group_ids = value.select {|k,v| v.try(:[], status_id.to_s).try(:include?, priority_id.to_s)}.keys
                user_ids += Group.where(id: group_ids).map(&:users).flatten.map(&:id)
              else
                nil
            end
          end
          user_ids.flatten.uniq
        end

        def intouch_recipients(protocol)
          User.where(id: recipient_ids(protocol))
        end

        def intouch_live_recipients(protocol)
          User.where(id: live_recipient_ids(protocol))
        end

        def performer
          assigned_to.present? ? assigned_to.name : 'Не назначена'
        end

        def inactive?
          interval = project.active_intouch_settings.
                              try(:[], 'working').try(:[], 'priority_notification').
                              try(:[], "#{priority_id}").try(:[], 'interval')
          interval.present? and updated_on < interval.to_i.hours.ago
        end

        def inactive_message
          hours = ((Time.now - updated_on) / 3600).round(1)
          "Бездействие #{hours} ч."
        end

        def telegram_message
          message = "[#{priority.try :name}] [#{status.try :name}] #{performer} - #{project.name}: #{subject} https://factory.southbridge.ru/issues/#{id}"
          message = "[Просроченная задача] #{message}" if overdue?
          message = "[Не установлена дата выполнения] #{message}" if without_due_date?
          message = "#{inactive_message} #{message}" if inactive?
          message
        end

        private

        def check_alarm
          if changed_attributes and (changed_attributes['priority_id'] or changed_attributes['status_id'])
            if alarm? or Intouch.work_time?
              IntouchSender.send_telegram_group_message(id, status_id, priority_id)
              IntouchSender.send_live_telegram_message(id)
              IntouchSender.send_live_email_message(id)
            end
          end
        end

        def send_new_message
          IntouchSender.send_live_telegram_message(id)
          IntouchSender.send_telegram_group_message(id, status_id, priority_id)
          IntouchSender.send_live_email_message(id)
        end

      end
    end

  end
end
Issue.send(:include, Intouch::IssuePatch)
