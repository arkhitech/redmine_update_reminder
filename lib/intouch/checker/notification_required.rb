module Intouch
  module Checker
    class NotificationRequired

      attr_reader :project, :issue

      def initialize(issue, project)
        @issue = issue
        @project = project
      end

      def call
        project.module_enabled?(:intouch) &&
          project.active? &&
          !issue.closed?
      end
    end
  end
end

