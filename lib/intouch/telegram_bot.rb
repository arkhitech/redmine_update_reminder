class Intouch::TelegramBot < TelegramCommon::Bot
  def initialize(command)
    @bot = Telegrammer::Bot.new(Intouch.bot_token)
    @logger = Logger.new(Rails.root.join('log/intouch', 'bot.log'))
    @command = command.is_a?(Telegrammer::DataTypes::Message) ? command : Telegrammer::DataTypes::Message.new(command)
  end

  # TODO: create group chat if it not exists
  # TODO: send message on account update
  def update
    private_command?(command) ? update_account : update_group
  end

  private

  def update_group
    chat = command.chat
    t_chat = TelegramGroupChat.where(tid: chat.id.abs).first_or_initialize(title: chat.title)

    user = command.from
    t_chat.update title: chat.title
    message = "Hello, #{user.first_name}! I've updated this group chat title in Redmine."
    send_message(command.chat.id, message)
    logger.info "#{user.first_name} renamed group title #{chat.title}"
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
end
