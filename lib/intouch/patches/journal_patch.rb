module Intouch
  module Patches
    module JournalPatch
      def self.included(base) # :nodoc:
        base.class_eval do
          unloadable

          after_create :send_live_message

          private

          def send_live_message
            project = issue.project
            if project.module_enabled?(:intouch) and project.active? and !issue.closed?
              if Intouch.work_time? or issue.alarm?
                if Intouch.active_protocols.include? 'telegram'

                  if (details.pluck(:prop_key) & %w(priority_id status_id)).present?
                    IntouchSender.send_live_telegram_group_message(issue.id)
                  end

                  IntouchSender.send_live_telegram_message(issue.id)
                end

                IntouchSender.send_live_email_message(issue.id) if Intouch.active_protocols.include? 'email'
              end
            end
          end


        end
      end

    end
  end
end
Journal.send(:include, Intouch::Patches::JournalPatch)
