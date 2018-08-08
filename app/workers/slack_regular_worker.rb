class SlackRegularWorker
  include Sidekiq::Worker

  def perform(issue_id, state)
    issue = Issue.find_by(id: issue_id) || return
    project = issue.project

    return unless Intouch::Regular::Checker::Base.new(
      issue: issue,
      state: state,
      project: project
    ).required?

    slack_accounts = SlackAccount.where(
        user_id: Intouch::Regular::RecipientsList.new(
            issue: issue,
            state: state,
            protocol: 'slack'
        ).call.map(&:id)
    ).to_a

    return if slack_accounts.empty?

    client = RedmineBots::Slack.bot_client

    channels = client.im_list

    return unless channels['ok']

    channels = client.im_list

    return unless channels['ok']

    channels.ims.select { |im| im.user.in?(slack_accounts.map(&:slack_id)) }.each do |channel|
      client.chat_postMessage(text: issue.as_markdown, channel: channel.id)
    end
  end
end
