class IntouchSender
  unloadable if Rails.env.production?

  def self.send_email_message(issue_id, state)
    EmailSenderWorker.perform_in(5.seconds, issue_id, state)
  end

  def self.send_telegram_message(issue_id, state)
    TelegramSenderWorker.perform_in(5.seconds, issue_id, state)
  end

  def self.send_telegram_group_message(issue_id, group_ids)
    TelegramGroupSenderWorker.perform_in(5.seconds, issue_id, group_ids)
  end

  def self.send_live_email_message(issue_id)
    EmailLiveSenderWorker.perform_in(5.seconds, issue_id)
  end

  def self.send_live_telegram_message(issue_id)
    TelegramLiveSenderWorker.perform_in(5.seconds, issue_id)
  end

  def self.send_live_telegram_group_message(issue_id, status_id, priority_id)
    issue = Issue.find issue_id
    telegram_groups_settings = issue.project.active_telegram_settings.try(:[], 'groups')

    if telegram_groups_settings

      group_ids = telegram_groups_settings.select do |k, v|
        v.try(:[], status_id.to_s).try(:include?, priority_id.to_s)
      end.keys

      only_unassigned_group_ids = telegram_groups_settings.select {|k,v| v.try(:[], 'only_unassigned').present?}.keys

      group_ids -= only_unassigned_group_ids unless issue.total_unassigned?

      if issue.alarm? or Intouch.work_time?

        TelegramGroupSenderWorker.perform_in(5.seconds, issue_id, group_ids, true)

      else
        anytime_group_ids = telegram_groups_settings.select {|k,v| v.try(:[], 'anytime').present?}.keys

        TelegramGroupSenderWorker.perform_in(5.seconds, issue_id, (group_ids & anytime_group_ids), true)
      end
    end
  end
end
