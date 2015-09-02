module Intouch
  module IssuePatch
    def self.included(base) # :nodoc:


      base.class_eval do
        before_save :check_alarm

        private

        def check_alarm
          if changed_attributes &&
              changed_attributes['priority_id'] &&
              IssuePriority.alarm_ids.include?(priority.id.to_s)

            TelegramSender.send_alarm_message(project_id, id)
          end
        end

      end
    end

  end
end
Issue.send(:include, Intouch::IssuePatch)
