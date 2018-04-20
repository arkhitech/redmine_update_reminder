module Intouch::Protocols
  class Slack < Base
    def handle_update(update)
      SlackLiveWorker.perform_async(update.issue.id, update.journal.id, update.live_recipients.map(&:id))
    end

    def send_regular_notification(issue, state)
      raise 'kek'
    end
  end
end
