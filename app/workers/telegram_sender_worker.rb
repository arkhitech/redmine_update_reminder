require_relative '../../lib/intouch/regular/checker/base'
require_relative '../../lib/intouch/regular/message/private'

class TelegramSenderWorker
  include Sidekiq::Worker

  def perform(issue_id, state)
    @issue = Issue.find issue_id
    @state = state
    Intouch.set_locale

    return unless notificable?

    issue.intouch_recipients('telegram', state).each do |user|
      telegram_account = user.telegram_account
      next unless telegram_account.present? && telegram_account.active?

      message = message(user)

      TelegramMessageSender.perform_async(telegram_account.telegram_id, message)
    end
  rescue ActiveRecord::RecordNotFound => e
    # ignore
  end

  private

  attr_reader :issue, :state

  def notificable?
    Intouch::Regular::Checker::Base.new(
      issue: issue,
      state: state,
      project: project
    ).required?
  end

  def message(user)
    Intouch::Regular::Message::Private.new(
      issue: issue,
      user: user,
      state: state,
      project: project
    ).message
  end

  def project
    @project ||= issue.project
  end

  def logger
    @logger ||= Logger.new(Rails.root.join('log/intouch', 'telegram-sender.log'))
  end
end
