module Intouch
  module Message
    class Formatter
      attr_reader :issue, :project # , :status, :priority

      def initialize(issue)
        @issue = issue
        @project = @issue.project
        @status = @issue.status
        @priority = @issue.priority
      end

      def title
        "#{project.title}: #{issue.subject}"
      end

      def assigned_to
        "#{I18n.t('field_assigned_to')}: #{performer}"
      end

      def priority
        if issue.alarm?
          "*#{I18n.t('field_priority')}: !!! #{@priority.name} !!!*"
        else
          "#{I18n.t('field_priority')}: #{@priority.name}"
        end
      end

      def status
        "#{I18n.t('field_status')}: #{@status.name}"
      end

      def link
        Intouch.issue_url(issue.id)
      end

      def performer
        @performer ||= issue.performer
      end

      def attention(text)
        "*!!! #{text} !!!*"
      end

      def bold(text)
        "*#{text}*"
      end
    end
  end
end
