module Intouch::Live::Checker
  class Base
    attr_reader :project, :issue, :journal

    def initialize(issue:, project:, journal: nil)
      @issue = issue
      @project = project
      @journal = journal
    end

    def required?
      project_enabled? && issue_open?
    end

    def project_enabled?
      project.module_enabled?(:intouch) && project.active?
    end

    def issue_open?
      !issue.closed? || journal_issue_state_open?
    end

    def journal_issue_state_open?
      return false unless journal.present?

      journal.new_status && !journal.new_status&.is_closed?
    end
  end
end
