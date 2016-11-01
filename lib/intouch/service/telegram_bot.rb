require 'telegrammer'

module Intouch
  module Service
    class TelegramBot
      EMAIL_REGEXP = /([^@\s]+@(?:[-a-z0-9]+\.)+[a-z]{2,})/i

      attr_reader :bot, :logger, :command

      def initialize(command)
        @bot     = Telegrammer::Bot.new(Intouch.bot_token)
        @logger  = Logger.new(Rails.root.join('log/intouch', 'bot.log'))
        @command = command.is_a?(Telegrammer::DataTypes::Message) ? command : Telegrammer::DataTypes::Message.new(command)
      end

      def call
        Intouch.set_locale

        command_text = command.text

        if command_text&.include?('start')
          start
        elsif command_text&.include?('/rename')
          # connect
        end
      end

      def start
        message = if telegram_account.new_record?
                    "Hello, #{telegram_user.first_name}! I've added your profile for Redmine notifications."
                  elsif telegram_account.active?
                    "Hello, #{telegram_user.first_name}! I've updated your profile for Redmine notifications."
                  else
                    "Hello again, #{telegram_user.first_name}! I've activated your profile for Redmine notifications."
                  end

        puts message

        update_account

        send_message(command.chat.id, message)
      end

      private

      def telegram_user
        command.from
      end

      def telegram_account
        @account ||= fetch_account
      end

      def fetch_account
        TelegramUser.where(tid: telegram_user.id).first_or_initialize
      end

      def update_account
        telegram_account.assign_attributes username:   telegram_user.username,
                                           first_name: telegram_user.first_name,
                                           last_name:  telegram_user.last_name,
                                           active:     true

        write_log_about_new_user if telegram_account.new_record?

        telegram_account.save!
      end

      def write_log_about_new_user
        logger.info "New telegram_user #{telegram_user.first_name} #{telegram_user.last_name} @#{telegram_user.username} added!"
      end

      def send_message(chat_id, message)
        bot.send_message(chat_id: chat_id, text: message)
      end
    end
  end
end
