module Intouch
  class GroupMessageSender
    extend ServiceInitializer

    attr_reader :project, :issue

    def initialize(issue, project)
      @issue = issue
      @project = project
    end

    def call
      return unless telegram_enabled?

      IntouchSender.send_live_telegram_group_message(issue.id)
    end

    private

    def telegram_enabled?
      Intouch.active_protocols.include?('telegram')
    end
  end
end
