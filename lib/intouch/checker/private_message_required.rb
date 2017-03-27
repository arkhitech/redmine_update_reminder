# this is for live

module Intouch
  module Checker
    class PrivateMessageRequired
      attr_reader :project, :issue

      def initialize(issue, project)
        @issue = issue
        @project = project
      end

      def call
        issue.alarm? || Intouch.work_time? || notify_always?
      end

      def required_recipients
        @required_recipients ||= always_notify_settings.keys
      end

      private

      def notify_always?
        required_recipients.present?
      end

      def always_notify_settings
        project.active_intouch_settings['always_notify'] || {}
      end
    end
  end
end
