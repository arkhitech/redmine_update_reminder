module Intouch::Live::Handler
  class NewIssue
    def initialize(issue)
      @issue = issue
      @project = @issue.project
    end

    def call
      return unless notification_required?

      Intouch.active_protocols.each do |name, protocol|
        update = Intouch::IssueUpdate.new(issue, nil, name)
        protocol.handle_update(update)
      end
    end

    private

    attr_reader :issue, :project

    def notification_required?
      Intouch::Live::Checker::Base.new(
        issue: issue,
        project: project
      ).required?
    end
  end
end
