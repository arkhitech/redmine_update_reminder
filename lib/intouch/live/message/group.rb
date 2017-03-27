module Intouch::Live::Message
  class Group
    attr_reader :project, :issue

    def initialize(issue, project)
      @issue = issue
      @project = project
    end

    def send
      return unless telegram_enabled?

      IntouchSender.send_live_telegram_group_message(issue.id)
    end

    private

    def telegram_enabled?
      Intouch.active_protocols.include?('telegram')
    end
  end
end
