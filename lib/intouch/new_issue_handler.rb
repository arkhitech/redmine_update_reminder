module Intouch
  class NewIssueHandler
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
      NotificationRequiredChecker.new(issue, project).call
    end

    def send_private_messages
      PrivateMessageSender.new(issue, project).call
    end

    def send_group_messages
      GroupMessageSender.new(issue, project).call
    end
  end
end
