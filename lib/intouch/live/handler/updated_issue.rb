module Intouch::Live::Handler
  class UpdatedIssue
    def initialize(journal)
      @journal = journal
      @issue = @journal.issue
      @project = @issue.project
    end

    def call
      logger.debug journal.inspect
      logger.debug issue.inspect

      return unless notification_required?

      logger.info 'notification required'

      Intouch.active_protocols.each do |name, protocol|
        update = Intouch::IssueUpdate.new(issue, journal, name)
        protocol.handle_update(update)
      end
    end

    private

    attr_reader :issue, :project, :journal

    def notification_required?
      Intouch::Live::Checker::Base.new(
        issue: issue,
        project: project,
        journal: journal
      ).required?
    end

    def logger
      @logger ||= Logger.new(Rails.root.join('log/intouch', 'live-updated.log'))
    end
  end
end
