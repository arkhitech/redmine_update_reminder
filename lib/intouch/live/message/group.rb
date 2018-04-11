module Intouch::Live::Message
  class Group
    attr_reader :project, :issue

    def initialize(issue, project, journal: nil)
      @issue = issue
      @project = project
      @journal = journal
    end

    def send
      return unless telegram_enabled?

      IntouchSender.send_live_telegram_group_message(issue.id, @journal&.id)
    end

    private

    def telegram_enabled?
      Intouch.active_protocols.include?('telegram')
    end
  end
end
