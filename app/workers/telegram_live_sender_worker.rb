class TelegramLiveSenderWorker
  include Sidekiq::Worker

  def perform(issue_id, required_recipients = [])
    @required_recipients = required_recipients
    logger.debug "START for issue_id #{issue_id}"

    Intouch.set_locale

    issue = Issue.find issue_id
    logger.debug issue.inspect

    base_message = issue.telegram_live_message

    logger.debug "base_message: #{base_message}"

    issue.intouch_live_recipients('telegram').each do |user|
      logger.debug "user: #{user.inspect}"

      telegram_account = user.telegram_account
      logger.debug "telegram_account: #{telegram_account.inspect}"
      next unless telegram_account.present? && telegram_account.active?

      roles_in_issue = []

      roles_in_issue << 'assigned_to' if issue.assigned_to_id == user.id
      roles_in_issue << 'watchers' if issue.watchers.pluck(:user_id).include? user.id
      roles_in_issue << 'author' if issue.author_id == user.id

      logger.debug "roles_in_issue: #{roles_in_issue.inspect}"

      next unless need_notification?(roles_in_issue)

      project  = issue.project
      settings = project.active_telegram_settings

      if settings.present?
        recipients = settings.select do |key, value|
          %w(author assigned_to watchers).include?(key) &&
            value.try(:[], issue.status_id.to_s).try(:include?, issue.priority_id.to_s)
        end.keys

        prefix = roles_for_prefix(recipients, roles_in_issue).map do |role|
          I18n.t("intouch.telegram_message.recipient.#{role}")
        end.join(', ')
      else
        prefix = nil
      end

      message = prefix.present? ? "#{prefix}\n#{base_message}" : base_message

      logger.debug message

      job = TelegramMessageSender.perform_async(telegram_account.telegram_id, message)

      logger.debug job.inspect
    end

    logger.debug "FINISH for issue_id #{issue_id}"
  rescue ActiveRecord::RecordNotFound => e
    # ignore
  end

  private

  attr_reader :required_recipients

  def logger
    @logger ||= Logger.new(Rails.root.join('log/intouch', 'telegram-live-sender.log'))
  end

  def need_notification?(roles_in_issue)
    return roles_in_issue unless required_recipients.present?

    (roles_in_issue & required_recipients).present?
  end

  def roles_for_prefix(recipients, roles_in_issue)
    return roles_in_issue & recipients unless required_recipients.present?

    roles_in_issue & recipients & required_recipients
  end
end
