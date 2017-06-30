class Intouch::TelegramBot < TelegramCommon::Bot
  def initialize(command)
    @logger = Logger.new(Rails.root.join('log/intouch', 'bot.log'))
    @command = command.is_a?(Telegram::Bot::Types::Message) ? command : Telegram::Bot::Types::Update.new(command).message
  end

  def call
    group_create_process if !private_command? && group_chat.new_record?
    super
  end

  def update
    private_command? ? private_update_process : group_update_process
  end

  private

  def private_update_process
    update_account
    send_message(I18n.t('intouch.bot.private.update.message'))
  end

  def group_create_process
    group_chat.save
    send_message(I18n.t('intouch.bot.group.start.message'))
    logger.info "New group #{chat.title} added!"
  end

  def group_update_process
    group_chat.update title: chat.title
    send_message(I18n.t('intouch.bot.group.update.message'))
    logger.info "#{user.first_name} renamed group title #{chat.title}"
  end

  def group_chat
    @group_chat ||= fetch_group_chat
  end

  def fetch_group_chat
    TelegramGroupChat.where(tid: chat_id.abs).first_or_initialize(title: chat.title)
  end

  def chat
    command.chat
  end

  def private_commands
    %w(start connect update help)
  end

  def group_commands
    %w(update help)
  end

  def private_help_message
    help_command_list(private_commands, namespace: 'intouch', type: 'private')
  end

  def group_help_message
    help_command_list(group_commands, namespace: 'intouch', type: 'group')
  end

  def bot_token
    Intouch.bot_token
  end
end
