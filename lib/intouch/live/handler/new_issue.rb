require_relative '../checker/base'
require_relative '../message/private'
require_relative '../message/group'

module Intouch::Live::Handler
  class NewIssue
    def initialize(issue)
      @issue = issue
      @project = @issue.project
    end

    def call
      return unless notification_required?

      send_private_messages
      send_group_messages
    end

    private

    attr_reader :issue, :project

    def notification_required?
      Intouch::Live::Checker::Base.new(
        issue: issue,
        project: project
      ).required?
    end

    def send_private_messages
      Intouch::Live::Message::Private.new(issue, project).send
    end

    def send_group_messages
      Intouch::Live::Message::Group.new(issue, project).send
    end
  end
end
