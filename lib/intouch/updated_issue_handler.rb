module Intouch
  class UpdatedIssueHandler
    def initialize(journal)
      @journal = journal
      @issue = @journal.issue
      @project = @issue.project
    end

    def call
      return unless notification_required?

      send_private_messages
      send_group_messages
    end

    private

    attr_reader :issue, :project, :journal

    def notification_required?
      Checker::NotificationRequired.new(issue, project).call
    end

    def send_private_messages
      PrivateMessageSender.new(issue, project).call
    end

    def send_group_messages
      return unless need_group_message?

      GroupMessageSender.new(issue, project).call
    end

    def need_group_message?
      (journal.details.pluck(:prop_key) & %w(priority_id status_id)).present?
    end
  end
end
