require_relative '../../lib/intouch/regular/checker/base'
require_relative '../../lib/intouch/regular/recipients_list'
require_relative '../../lib/intouch/regular/message/private'

class TelegramSenderWorker
  include Sidekiq::Worker

  def perform(issue_id, state)
    @issue = Issue.find_by(id: issue_id)
    @state = state

    return unless @issue.present?
    return unless notificable?
    return unless users.present?

    users.each { |user| send_message(user) }
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

  def users
    @users ||= Intouch::Regular::RecipientsList.new(
      issue: issue,
      state: state,
      protocol: 'telegram'
    ).call
  end

  def send_message(user)
    Intouch::Regular::Message::Private.new(
      issue: issue,
      user: user,
      state: state,
      project: project
    ).send
  end

  def project
    @project ||= issue.project
  end

  def logger
    @logger ||= Logger.new(Rails.root.join('log/intouch', 'telegram-sender.log'))
  end
end
