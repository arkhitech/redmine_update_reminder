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


        def email_recipients
          if notification_status
            user_ids = project.email_settings[notification_status].map do |key, value|
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
            User.where(id: user_ids).pluck(:email)
          end
        end

        private

        def check_alarm
          if changed_attributes
            if changed_attributes['priority_id'] &&
                IssuePriority.alarm_ids.include?(priority.id.to_s)
              TelegramSender.send_alarm_message(project_id, id)
            elsif changed_attributes['status_id']
              if IssuePriority.alarm_ids.include?(priority.id.to_s)
                TelegramSender.send_alarm_message(project_id, id)
              elsif IssueStatus.new_ids.include?(status.id.to_s)
                TelegramSender.send_new_message(project_id, id)
              elsif IssueStatus.working_ids.include?(status.id.to_s)
                TelegramSender.send_working_message(project_id, id)
              elsif IssueStatus.feedback_ids.include?(status.id.to_s)
                TelegramSender.send_feedback_message(project_id, id)
              end
            end
          end
        end

        def send_new_message
          TelegramSender.send_new_message(project_id, id)
        end

      end
    end

  end
end
Issue.send(:include, Intouch::IssuePatch)
