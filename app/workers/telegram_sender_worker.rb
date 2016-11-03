class TelegramSenderWorker
  include Sidekiq::Worker
  TELEGRAM_SENDER_LOG = Logger.new(Rails.root.join('log/intouch', 'telegram-sender.log'))

  def perform(issue_id, state)
    Intouch.set_locale
    issue = Issue.find issue_id

    return unless issue.notificable_for_state? state

    base_message = issue.telegram_message

    issue.intouch_recipients('telegram', state).each do |user|
      telegram_account = user.telegram_account
      next unless telegram_account.present? && telegram_account.active?

      roles_in_issue = []

      roles_in_issue << 'assigned_to' if issue.assigned_to_id == user.id
      roles_in_issue << 'watchers' if issue.watchers.pluck(:user_id).include? user.id
      roles_in_issue << 'author' if issue.author_id == user.id

      project = issue.project
      settings = project.active_telegram_settings.try(:[], state)

      if settings.present?
        recipients = settings.select do |key, _value|
          %w(author assigned_to watchers).include?(key)
        end.keys

        prefix = (roles_in_issue & recipients).map do |role|
          I18n.t("intouch.telegram_message.recipient.#{role}")
        end.join(', ')
      else
        prefix = nil
      end

      message = prefix.present? ? "#{prefix}\n#{base_message}" : base_message

      TelegramMessageSender.perform_async(telegram_account.telegram_id, message)
    end
  rescue ActiveRecord::RecordNotFound => e
    # ignore
  end
end
