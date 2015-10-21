module Intouch
  module IssuePatch
    def self.included(base) # :nodoc:
      base.class_eval do
        unloadable if Rails.env.production?

        store :intouch_data, accessors: %w(last_notification)

        before_save :check_alarm
        after_create :send_new_message

        def self.alarms
          Issue.where(priority_id: IssuePriority.alarm_ids)
        end

        def self.working
          Issue.where(status_id: IssueStatus.working_ids)
        end

        def self.feedbacks
          Issue.where(status_id: IssueStatus.feedback_ids)
        end

        def alarm?
          IssuePriority.alarm_ids.include? priority_id
        end

        def unassigned?
          assigned_to.nil?
        end

        def assigned_to_group?
          assigned_to.class == Group
        end

        def working?
          IssueStatus.working_ids.include? status_id
        end

        def feedback?
          IssueStatus.feedback_ids.include? status_id
        end

        def without_due_date?
          !due_date.present? and created_on < 1.day.ago
        end

        def notification_state
          %w(unassigned assigned_to_group overdue without_due_date working feedback).select { |s| send("#{s}?") }.try :first
        end

        def recipient_ids(protocol, state = notification_state)
          if project.send("active_#{protocol}_settings") && state && project.send("active_#{protocol}_settings")[state]
            project.send("active_#{protocol}_settings")[state].map do |key, value|
              case key
                when 'author'
                  author.id
                when 'assigned_to'
                  (assigned_to.class == Group) ? assigned_to.user_ids : assigned_to.id
                when 'watchers'
                  watchers.pluck(:user_id)
                else
                  nil
              end
            end.flatten.uniq
          end
        end

        def live_recipient_ids(protocol)
          settings = project.send("active_#{protocol}_settings")
          if settings.present?
            recipients = settings.select { |k, v| %w(author assigned_to watchers user_groups).include? k }

            user_ids = []
            recipients.each_pair do |key, value|
              case key
                when 'author'
                  user_ids << author.id if value.try(:[], status_id.to_s).try(:include?, priority_id.to_s)
                when 'assigned_to'
                  if value.try(:[], status_id.to_s).try(:include?, priority_id.to_s)
                    if assigned_to.class == Group
                      user_ids += assigned_to.user_ids
                    else
                      user_ids << assigned_to.id
                    end
                  end
                when 'watchers'
                  user_ids << watchers.pluck(:user_id) if value.try(:[], status_id.to_s).try(:include?, priority_id.to_s)
                else
                  nil
              end
            end
            user_ids.flatten.uniq
          else
            []
          end
        end

        def intouch_recipients(protocol, state = notification_state)
          User.where(id: recipient_ids(protocol, state))
        end

        def intouch_live_recipients(protocol)
          User.where(id: live_recipient_ids(protocol))
        end

        def performer
          if assigned_to.present?
            if assigned_to.class == Group
              "Назначена на группу: #{assigned_to.name}"
            else
              assigned_to.name
            end
          end
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

        def updated_by
          journals.last.user.to_s if journals.present?
        end

        def telegram_message
          message = "#{project.name}: #{priority.try :name} [#{status.try :name}] #{performer} -  #{subject} - #{Intouch.issue_url(id)}"
          message = "[Просроченная задача] #{message}" if overdue?
          message = "#{inactive_message}: #{message}" if inactive?
          message = "*** Установите дату выполнения *** \n#{message}" if without_due_date?
          message = "*** Возьмите в работу *** \n#{message}" if overdue?
          message = "*** Назначьте исполнителя *** \n#{message}" if unassigned? or assigned_to_group?
          message = "#{message}\nОбновил #{updated_by}" if updated_by.present?
          message
        end

        private

        def check_alarm
          if project.module_enabled?(:intouch) and project.active? and
            !closed? and changed_attributes and (changed_attributes['priority_id'] or changed_attributes['status_id'])
            if alarm? or Intouch.work_time?
              IntouchSender.send_live_telegram_group_message(id, status_id, priority_id)
              IntouchSender.send_live_telegram_message(id)
              IntouchSender.send_live_email_message(id)
            end
          end
        end

        def send_new_message
          if project.module_enabled?(:intouch) and project.active? and !closed?
            IntouchSender.send_live_telegram_message(id)
            IntouchSender.send_live_telegram_group_message(id, status_id, priority_id)
            IntouchSender.send_live_email_message(id)
          end
        end

      end
    end

  end
end
Issue.send(:include, Intouch::IssuePatch)
