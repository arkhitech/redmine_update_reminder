class TelegramLiveSenderWorker
  include Sidekiq::Worker
  TELEGRAM_LIVE_SENDER_LOG = Logger.new(Rails.root.join('log/intouch', 'telegram-live-sender.log'))

  def perform(issue_id)
    TELEGRAM_LIVE_SENDER_LOG.debug "START for issue_id #{issue_id}"

    Intouch.set_locale

    issue = Issue.find issue_id
    TELEGRAM_LIVE_SENDER_LOG.debug issue.inspect

    base_message = issue.telegram_live_message

    TELEGRAM_LIVE_SENDER_LOG.debug "base_message: #{base_message}"

    issue.intouch_live_recipients('telegram').each do |user|
      TELEGRAM_LIVE_SENDER_LOG.debug "user: #{user.inspect}"

      telegram_account = user.telegram_account
      TELEGRAM_LIVE_SENDER_LOG.debug "telegram_account: #{telegram_account.inspect}"
      next unless telegram_account.present? && telegram_account.active?

      roles_in_issue = []

      roles_in_issue << 'assigned_to' if issue.assigned_to_id == user.id
      roles_in_issue << 'watchers' if issue.watchers.pluck(:user_id).include? user.id
      roles_in_issue << 'author' if issue.author_id == user.id

      TELEGRAM_LIVE_SENDER_LOG.debug "roles_in_issue: #{roles_in_issue.inspect}"

      project  = issue.project
      settings = project.active_telegram_settings

      if settings.present?
        recipients = settings.select do |key, value|
          %w(author assigned_to watchers).include?(key) &&
            value.try(:[], issue.status_id.to_s).try(:include?, issue.priority_id.to_s)
        end.keys

        prefix = (roles_in_issue & recipients).map do |role|
          I18n.t("intouch.telegram_message.recipient.#{role}")
        end.join(', ')
      else
        prefix = nil
      end

      message = prefix.present? ? "#{prefix}\n#{base_message}" : base_message

      TELEGRAM_LIVE_SENDER_LOG.debug message

      job = TelegramMessageSender.perform_async(telegram_account.telegram_id, message)

      TELEGRAM_LIVE_SENDER_LOG.debug job.inspect
    end

    TELEGRAM_LIVE_SENDER_LOG.debug "FINISH for issue_id #{issue_id}"
  rescue ActiveRecord::RecordNotFound => e
    # ignore
  end
end
