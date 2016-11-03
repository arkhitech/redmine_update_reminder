class Intouch::TelegramBot < TelegramCommon::Bot

  def initialize(command)
    @bot = Telegrammer::Bot.new(Intouch.bot_token)
    @logger = Logger.new(Rails.root.join('log/intouch', 'bot.log'))
    @command = command.is_a?(Telegrammer::DataTypes::Message) ? command : Telegrammer::DataTypes::Message.new(command)
  end

  def call
    Intouch.set_locale

    command_text = command.text

    if command_text&.include?('start') || command_text&.include?('update')
      start
    elsif command_text&.include?('/connect')
      connect
    elsif command_text&.include?('/rename')
      # rename not implemented yet
    end
  end


end
