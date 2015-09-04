module Intouch
  module IssuePatch
    def self.included(base) # :nodoc:
      base.class_eval do
        unloadable

        before_save :check_alarm
        after_create :send_new_message

        def self.alarms
          Issue.where(priority_id: IssuePriority.alarm_ids, status_id: IssueStatus.alarm_ids)
        end

        def self.news
          Issue.where(status_id: IssueStatus.new_ids).where.not(priority_id: IssuePriority.alarm_ids)
        end

        def self.working
          Issue.where(status_id: IssueStatus.wip_ids).where.not(priority_id: IssuePriority.alarm_ids)
        end

        def self.feedbacks
          Issue.where(status_id: IssueStatus.feedback_ids).where.not(priority_id: IssuePriority.alarm_ids)
        end

        private

        def check_alarm
          if changed_attributes
            if changed_attributes['priority_id'] &&
                IssuePriority.alarm_ids.include?(priority.id.to_s)
              TelegramSender.send_alarm_message(project_id, id)
            elsif changed_attributes['status_id']
              TelegramSender.send_new_message(project_id, id) if IssueStatus.new_ids.include?(status.id.to_s)
              TelegramSender.send_working_message(project_id, id) if IssueStatus.working_ids.include?(status.id.to_s)
              TelegramSender.send_feedback_message(project_id, id) if IssueStatus.feedback_ids.include?(status.id.to_s)
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
