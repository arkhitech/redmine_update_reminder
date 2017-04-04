class TelegramGroupSenderWorker
  include Sidekiq::Worker

  def perform(issue_id, group_ids, state)
    return unless group_ids.present?

    @issue = Issue.find_by(id: issue_id)
    @group_ids = group_ids
    @state = state

    return unless @issue.present?
    return unless notificable?
    return unless groups.present?

    log

    groups.each { |group| send_message(group) }
  end

  private

  attr_reader :issue, :state, :group_ids

  def notificable?
    Intouch::Regular::Checker::Base.new(
      issue: issue,
      state: state,
      project: project
    ).required?
  end

  def groups
    @groups ||= TelegramGroupChat.where(id: group_ids).uniq
  end

  def send_message(group)
    return unless group.tid.present?
    TelegramMessageSender.perform_async(-group.tid, message)
  end

  def message
    @message ||= issue.telegram_message
  end

  def project
    @project ||= issue.project
  end

  def log
    logger.info '========================================='
    logger.info "Notification for state: #{state}"
    logger.info message
    logger.debug issue.inspect
    logger.debug group_ids.inspect
    logger.info '========================================='
  end

  def logger
    @logger ||= Logger.new(Rails.root.join('log/intouch', 'telegram-group-sender.log'))
  end
end
