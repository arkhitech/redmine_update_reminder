class TelegramSender
  unloadable if Rails.env.production?

  def self.send_message(issue_id)
    TelegramSenderWorker.perform_in(5.seconds, issue_id)
  end

  def self.send_group_message(issue_id, status_id, priority_id)
    issue = Issue.find issue_id
    telegram_groups_settings = issue.project.telegram_settings.try(:[], 'groups')
    if telegram_groups_settings
      group_ids = telegram_groups_settings.select {|k,v| v.try(:[], status_id.to_s).try(:include?, priority_id.to_s)}.keys
      TelegramGroupSenderWorker.perform_in(5.seconds, issue_id, group_ids)
    end
  end
end
