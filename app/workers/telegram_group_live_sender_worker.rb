class TelegramGroupLiveSenderWorker
  include Sidekiq::Worker
  TELEGRAM_GROUP_LIVE_SENDER_LOG = Logger.new(Rails.root.join('log/intouch', 'telegram-group-live-sender.log'))

  def perform(issue_id)
    Intouch.set_locale

    issue = Issue.find issue_id
    telegram_groups_settings = issue.project.active_telegram_settings.try(:[], 'groups')

    return unless telegram_groups_settings.present?

    group_ids = telegram_groups_settings.select do |k, v|
      v.try(:[], issue.status_id.to_s).try(:include?, issue.priority_id.to_s)
    end.keys

    only_unassigned_group_ids = telegram_groups_settings.select { |k, v| v.try(:[], 'only_unassigned').present? }.keys

    group_ids -= only_unassigned_group_ids unless issue.total_unassigned?

    group_for_send_ids = if issue.alarm? or Intouch.work_time?

                           group_ids

                         else
                           anytime_group_ids = telegram_groups_settings.select { |k, v| v.try(:[], 'anytime').present? }.keys

                           (group_ids & anytime_group_ids)
                         end

    return unless group_for_send_ids.present?

    message = issue.telegram_live_message

    TelegramGroupChat.where(id: group_for_send_ids).uniq.each do |group|
      next unless group.tid.present?
      TelegramMessageSender.perform_async(-group.tid, message)
    end
  rescue ActiveRecord::RecordNotFound => e
    # ignore
  end
end
