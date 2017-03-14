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

    private unless Rails.env.test?

    attr_reader :issue

    def send_private_messages
      return unless need_private_message?

      send_telegram_private_messages
      send_email_messages
    end

    def need_private_message?
      issue.alarm? || Intouch.work_time? || private_message_required?
    end

    def send_telegram_private_messages
      return unless telegram_enabled?

      IntouchSender.send_live_telegram_message(issue.id, required_recipients)
    end

    def send_email_messages
      return unless email_enabled?

      IntouchSender.send_live_email_message(issue.id, required_recipients)
    end

    def send_group_messages
      return unless telegram_enabled?

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

    def telegram_enabled?
      Intouch.active_protocols.include?('telegram')
    end

    def email_enabled?
      Intouch.active_protocols.include?('email')
    end

    def private_message_required?
      reqired_recipients.present?
    end

    def required_recipients
      always_notify_settings.keys
    end

    def always_notify_settings
      @always_notify_settings ||= project.intouch_settings['always_notify'] || {}
    end
  end
end
