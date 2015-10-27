class TelegramLiveSenderWorker
  include Sidekiq::Worker
  TELEGRAM_LIVE_SENDER_LOG = Logger.new(Rails.root.join('log/intouch', 'telegram-live-sender.log'))

  def perform(issue_id)
    Intouch.set_locale
    issue = Issue.find issue_id

    base_message = issue.telegram_live_message

    token = Setting.plugin_redmine_intouch['telegram_bot_token']
    bot = Telegrammer::Bot.new(token)

    issue.intouch_live_recipients('telegram').each do |user|

      telegram_user = user.telegram_user
      next unless telegram_user.present? and telegram_user.active?

      roles_in_issue = []

      roles_in_issue << 'assigned_to' if issue.assigned_to_id == user.id
      roles_in_issue << 'watchers' if issue.watchers.pluck(:user_id).include? user.id
      roles_in_issue << 'author' if issue.author_id == user.id

      project = issue.project
      settings = project.active_telegram_settings

      recipients = settings.select do |key, value|
        %w(author assigned_to watchers).include?(key) and
            value.try(:[], issue.status_id.to_s).try(:include?, issue.priority_id.to_s)
      end.keys

      prefix = (roles_in_issue & recipients).map do |role|
        I18n.t("intouch.telegram_message.recipient.#{role}")
      end

      message = prefix.present? ? "#{prefix}\n#{base_message}" : base_message

      begin
        bot.send_message(chat_id: telegram_user.tid, text: message, disable_web_page_preview: true)
      rescue Telegrammer::Errors::BadRequestError => e
        if e.message.include? 'Bot was kicked'
          telegram_user.deactivate
          TELEGRAM_LIVE_SENDER_LOG.info "Bot was kicked from chat. Deactivate #{telegram_user.inspect}"
        else
          TELEGRAM_LIVE_SENDER_LOG.error "#{e.class}: #{e.message}"
          TELEGRAM_LIVE_SENDER_LOG.debug "#{issue.inspect}"
          TELEGRAM_LIVE_SENDER_LOG.debug "#{user.inspect}"
          TELEGRAM_LIVE_SENDER_LOG.debug "#{telegram_user.inspect}"
        end
      end
    end
  rescue ActiveRecord::RecordNotFound => e
    TELEGRAM_LIVE_SENDER_LOG.error "#{e.class}: #{e.message}"
  end

end
