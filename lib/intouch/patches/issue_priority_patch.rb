module Intouch
  module IssuePriorityPatch
    def self.included(base) # :nodoc:


      base.class_eval do
        unloadable

        def self.alarm_ids
          settings = Setting.plugin_redmine_intouch
          settings.keys.select { |key| key.include?('alarm_priority') }.map { |key| key.split('_').last }
        end

      end
    end

  end
end
IssuePriority.send(:include, Intouch::IssuePriorityPatch)
