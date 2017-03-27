module Intouch::Live::Message
  class Private
    attr_reader :project, :issue

    def initialize(issue, project)
      @issue = issue
      @project = project
    end

    def send
      return unless need_private_message?

      send_telegram_private_messages
      send_email_messages
    end

    private

    def need_private_message?
      required_checker.required?
    end

    def required_recipients
      required_checker.required_recipients
    end

    def send_telegram_private_messages
      return unless telegram_enabled?

      IntouchSender.send_live_telegram_message(issue.id, required_recipients)
    end

    def send_email_messages
      return unless email_enabled?

      IntouchSender.send_live_email_message(issue.id, required_recipients)
    end

    def telegram_enabled?
      Intouch.active_protocols.include?('telegram')
    end

    def email_enabled?
      Intouch.active_protocols.include?('email')
    end

    def required_checker
      @required_checker ||= Intouch::Live::Checker::Private.new(issue, project)
    end
  end
end
