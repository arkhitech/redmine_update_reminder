module Intouch
  class PrivateMessageSender
    attr_reader :project, :issue

    def initialize(issue, project)
      @issue = issue
      @project = project
    end

    def call
      return unless need_private_message?

      send_telegram_private_messages
      send_email_messages
    end

    private

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

    def private_message_required?
      required_recipients.present?
    end

    def required_recipients
      always_notify_settings.keys
    end

    def always_notify_settings
      @always_notify_settings ||= project.intouch_settings['always_notify'] || {}
    end

    def telegram_enabled?
      Intouch.active_protocols.include?('telegram')
    end

    def email_enabled?
      Intouch.active_protocols.include?('email')
    end
  end
end
