class TelegramLiveSenderWorker
  include Sidekiq::Worker

  def perform(issue_id, journal_id, recipient_ids)
    logger.debug "START for issue_id #{issue_id}"

    Intouch.set_locale

    issue = Intouch::IssueDecorator.new(Issue.find(issue_id), journal_id)
    logger.debug issue.inspect

    message = issue.telegram_live_message

    logger.debug "message: #{message}"

    User.where(id: recipient_ids).each do |user|
      logger.debug "user: #{user.inspect}"

      telegram_account = user.telegram_account
      logger.debug "telegram_account: #{telegram_account.inspect}"
      next unless telegram_account.present? && telegram_account.active?

      logger.debug message

      job = TelegramMessageSender.perform_async(telegram_account.telegram_id, message)

      logger.debug job.inspect
    end

    logger.debug "FINISH for issue_id #{issue_id}"
  rescue ActiveRecord::RecordNotFound => e
    # ignore
  end

  private

  def logger
    @logger ||= Logger.new(Rails.root.join('log/intouch', 'telegram-live-sender.log'))
  end
end
