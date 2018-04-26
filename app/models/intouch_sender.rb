class IntouchSender
  unloadable

  def self.send_email_message(issue_id, state)
    EmailSenderWorker.perform_async(issue_id, state)
  end

  def self.send_telegram_message(issue_id, state)
    TelegramSenderWorker.perform_async(issue_id, state)
  end

  def self.send_telegram_group_message(issue_id, group_ids, state)
    TelegramGroupSenderWorker.perform_async(issue_id, group_ids, state)
  end

  def self.send_live_email_message(issue_id, journal_id, required_recipients = [])
    EmailLiveSenderWorker.perform_async(issue_id, journal_id, required_recipients)
  end

  def self.send_live_telegram_message(issue_id, journal_id, required_recipients = [])
    TelegramLiveSenderWorker.perform_async(issue_id, journal_id, required_recipients)
  end

  def self.send_live_telegram_group_message(issue_id, journal_id)
    TelegramGroupLiveSenderWorker.perform_async(issue_id, journal_id)
  end
end
