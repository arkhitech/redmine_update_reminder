module Intouch::Protocols
  class Email
    def handle_update(update)
      EmailLiveSenderWorker.perform_async(update.issue.id, update&.journal&.id, update.live_recipients.map(&:id))
    end

    def send_regular_notification(issue, state)
      EmailSenderWorker.perform_async(issue.id, state)
    end
  end
end
