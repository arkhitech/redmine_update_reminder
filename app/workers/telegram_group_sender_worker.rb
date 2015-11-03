class TelegramGroupSenderWorker
  include Sidekiq::Worker
  TELEGRAM_GROUP_SENDER_LOG = Logger.new(Rails.root.join('log/intouch', 'telegram-group-sender.log'))

  def perform(issue_id, group_ids, state)
    return unless group_ids.present?

    Intouch.set_locale
    issue = Issue.find issue_id

    return unless issue.notificable_for_state? state

    message = issue.telegram_message

    TelegramGroupChat.where(id: group_ids).uniq.each do |group|
      next unless group.tid.present?
      TelegramMessageSender.perform_async(-group.tid, message)
    end
  rescue ActiveRecord::RecordNotFound => e
    TELEGRAM_GROUP_LIVE_SENDER_LOG.error "#{e.class}: #{e.message}"
  end
end
