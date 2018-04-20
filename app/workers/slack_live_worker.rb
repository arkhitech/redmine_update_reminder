class SlackLiveWorker
  include Sidekiq::Worker

  def perform(issue_id, journal_id, recipient_ids)
    issue = Issue.find_by(id: issue_id) || return
    journal = Journal.find_by(id: journal_id) || return

    slack_accounts = SlackAccount.where(user_id: recipient_ids)

    client = RedmineBots::Slack.web_client

    channels = client.im_list

    return unless channels['ok']

    channels.ims.select { |im| im.user.in?(slack_accounts.map(&:slack_id)) }.each do |channel|
      client.chat_postMessage(text: 'test', channel: channel.id)
    end
  end
end
