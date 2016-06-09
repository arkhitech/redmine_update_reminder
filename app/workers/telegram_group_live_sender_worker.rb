class TelegramGroupLiveSenderWorker
  include Sidekiq::Worker
  TELEGRAM_GROUP_LIVE_SENDER_LOG = Logger.new(Rails.root.join('log/intouch', 'telegram-group-live-sender.log'))

  def perform(issue_id)
    TELEGRAM_GROUP_LIVE_SENDER_LOG.debug "START for issue_id #{issue_id}"
    Intouch.set_locale

    issue = Issue.find issue_id
    TELEGRAM_GROUP_LIVE_SENDER_LOG.debug issue.inspect

    telegram_groups_settings = issue.project.active_telegram_settings.try(:[], 'groups')
    TELEGRAM_GROUP_LIVE_SENDER_LOG.debug "telegram_groups_settings: #{telegram_groups_settings.inspect}"

    return unless telegram_groups_settings.present?

    group_ids = telegram_groups_settings.select do |k, v|
      v.try(:[], issue.status_id.to_s).try(:include?, issue.priority_id.to_s)
    end.keys

    TELEGRAM_GROUP_LIVE_SENDER_LOG.debug "group_ids: #{group_ids.inspect}"

    only_unassigned_group_ids = telegram_groups_settings.select { |k, v| v.try(:[], 'only_unassigned').present? }.keys

    TELEGRAM_GROUP_LIVE_SENDER_LOG.debug "only_unassigned_group_ids: #{group_ids.inspect}"

    group_ids -= only_unassigned_group_ids unless issue.total_unassigned?

    TELEGRAM_GROUP_LIVE_SENDER_LOG.debug "group_ids: #{group_ids.inspect} (total_unassigned? = #{issue.total_unassigned?.inspect})"

    group_for_send_ids = if issue.alarm? or Intouch.work_time?
                           TELEGRAM_GROUP_LIVE_SENDER_LOG.debug 'Alarm or work time'

                           group_ids

                         else
                           TELEGRAM_GROUP_LIVE_SENDER_LOG.debug 'Anytime notifications'

                           anytime_group_ids = telegram_groups_settings.select { |k, v| v.try(:[], 'anytime').present? }.keys

                           (group_ids & anytime_group_ids)
                         end

    TELEGRAM_GROUP_LIVE_SENDER_LOG.debug "group_for_send_ids: #{group_for_send_ids.inspect}"

    return unless group_for_send_ids.present?

    message = issue.telegram_live_message

    TELEGRAM_GROUP_LIVE_SENDER_LOG.debug "message: #{message}"

    TelegramGroupChat.where(id: group_for_send_ids).uniq.each do |group|
      TELEGRAM_GROUP_LIVE_SENDER_LOG.debug "group: #{group.inspect}"
      next unless group.tid.present?

      job = TelegramMessageSender.perform_async(-group.tid, message)

      TELEGRAM_GROUP_LIVE_SENDER_LOG.debug job.inspect
    end
    TELEGRAM_GROUP_LIVE_SENDER_LOG.debug "DONE for issue_id #{issue_id}"
  rescue ActiveRecord::RecordNotFound => e
    # ignore
  end
end
