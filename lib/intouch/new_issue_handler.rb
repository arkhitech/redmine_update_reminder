module Intouch
  class NewIssueHandler
    def initialize(issue)
      @issue = issue
    end

    def call
      return -1 unless need_notification?

      send_private_messages
      send_group_messages
    end

    private

    attr_reader :issue

    def send_private_messages
      return unless need_private_message?

      send_telegram_private_messages
      send_email_messages
    end

    def need_private_message?
      issue.alarm? || Intouch.work_time?
    end

    def send_telegram_private_messages
      return unless Intouch.active_protocols.include?('telegram')

      IntouchSender.send_live_telegram_message(issue.id)
    end

    def send_email_messages
      return unless Intouch.active_protocols.include?('email')

      IntouchSender.send_live_email_message(issue.id)
    end

    def send_group_messages
      return unless Intouch.active_protocols.include?('telegram')

      IntouchSender.send_live_telegram_group_message(issue.id)
    end

    def need_notification?
      project.module_enabled?(:intouch) &&
        project.active? &&
        !issue.closed?
    end

    def project
      @project ||= issue.project
    end
  end
end
