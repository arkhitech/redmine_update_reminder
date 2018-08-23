module Intouch::Protocols
  class Email
    def handle_update(update)
      recipients = update.live_recipients.group_by(&:class).map do |klass, recipients|
        { klass.name => recipients.map(&:id) }
      end.reduce(:merge) || {}

      EmailLiveSenderWorker.perform_async(update.issue.id, update&.journal&.id, recipients)
    end

    def send_regular_notification(issue, state)
      EmailSenderWorker.perform_async(issue.id, state)
    end
  end
end
