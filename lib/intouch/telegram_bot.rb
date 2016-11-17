class Intouch::TelegramBot < TelegramCommon::Bot
  def initialize(command)
    @bot = Telegrammer::Bot.new(Intouch.bot_token)
    @logger = Logger.new(Rails.root.join('log/intouch', 'bot.log'))
    @command = command.is_a?(Telegrammer::DataTypes::Message) ? command : Telegrammer::DataTypes::Message.new(command)
  end

  private

  def private_commands
    %w(start connect update help)
  end

  def group_commands
    %w(update help)
  end

  def private_help_message
    help_command_list(private_commands, namespace: 'intouch')
  end
end
