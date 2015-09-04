module Intouch
  module IssueStatusPatch
    def self.included(base) # :nodoc:
      base.class_eval do
        unloadable

        def self.alarm_ids
          new_ids + feedback_ids + working_ids
        end

        def self.new_ids
          settings = Setting.plugin_redmine_intouch
          settings.keys.select{|key| key.include?('new_status')}.map{|key| key.split('_').last }
        end

        def self.feedback_ids
          settings = Setting.plugin_redmine_intouch
          settings.keys.select{|key| key.include?('feedback_status')}.map{|key| key.split('_').last }
        end

        def self.working_ids
          settings = Setting.plugin_redmine_intouch
          settings.keys.select{|key| key.include?('working_status')}.map{|key| key.split('_').last }
        end

      end
    end
  end
end
IssueStatus.send(:include, Intouch::IssueStatusPatch)
