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

        def recipients(protocol)
          User.where(id: recipient_ids(protocol))
        end

        def telegram_message
          "[#{priority.try :name}] [#{status.try :name}] #{project.name}: #{subject} https://factory.southbridge.ru/issues/#{id}"
        end

        private

        def check_alarm
          if changed_attributes and (changed_attributes['priority_id'] or changed_attributes['status_id'])
            TelegramSender.send_group_message(id, status_id, priority_id)

            if IssuePriority.alarm_ids.include?(priority.id) or IssueStatus.alarm_ids.include?(status.id)
              TelegramSender.send_message(id)
            end
          end
        end

        def send_new_message
          TelegramSender.send_message(id)
          TelegramSender.send_group_message(id, status_id, priority_id)
        end

      end
    end

  end
end
Issue.send(:include, Intouch::IssuePatch)
