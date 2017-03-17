module Intouch
  class NewIssueHandler
    extend ServiceInitializer

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
      Checker::NotificationRequired.new(issue, project).call
    end

    def send_private_messages
      PrivateMessageSender.call(issue, project)
    end

    def send_group_messages
      GroupMessageSender.call(issue, project)
    end
  end
end
