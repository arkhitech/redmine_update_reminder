module Intouch
  module IssueStatusPatch
    def self.included(base) # :nodoc:
      base.class_eval do

        def self.alarm_ids
          new_ids + feedback_ids + wip_ids
        end

        def self.working_ids
          feedback_ids + wip_ids
        end

        def self.new_ids
          settings = Setting.plugin_redmine_intouch
          settings.keys.select{|key| key.include?('new_status')}.map{|key| key.split('_').last }
        end

        def self.feedback_ids
          settings = Setting.plugin_redmine_intouch
          settings.keys.select{|key| key.include?('feedback_status')}.map{|key| key.split('_').last }
        end

        def self.wip_ids
          settings = Setting.plugin_redmine_intouch
          settings.keys.select{|key| key.include?('work_in_progress_status')}.map{|key| key.split('_').last }
        end

      end
    end
  end
end
IssueStatus.send(:include, Intouch::IssueStatusPatch)
