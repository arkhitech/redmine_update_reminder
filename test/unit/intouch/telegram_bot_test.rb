require File.expand_path('../../../test_helper', __FILE__)

class Intouch::TelegramBotTest < ActiveSupport::TestCase
  fixtures :users, :email_addresses, :roles

  fixtures :users, :email_addresses, :roles

  setup do
    Intouch.stubs(:bot_token)
    Telegrammer::Bot.any_instance.stubs(:get_me)
  end

  context '/start' do
    setup do
      @telegram_message = ActionController::Parameters.new(
        from: { id:         123,
                username:   'dhh',
                first_name: 'David',
                last_name:  'Haselman' },
        chat: { id: 123 },
        text: '/start'
      )

      @bot_service = Intouch::TelegramBot.new(@telegram_message)
    end

    context 'without user' do
      setup do
        Intouch::TelegramBot.any_instance
          .expects(:send_message)
          .with(123, I18n.t('telegram_common.bot.start.instruction_html'))
      end

      should 'create telegram account' do
        assert_difference('TelegramCommon::Account.count') do
          @bot_service.start
        end

        telegram_account = TelegramCommon::Account.last
        assert_equal 123, telegram_account.telegram_id
        assert_equal 'dhh', telegram_account.username
        assert_equal 'David', telegram_account.first_name
        assert_equal 'Haselman', telegram_account.last_name
        assert telegram_account.active
      end

      should 'update telegram account' do
        telegram_account = TelegramCommon::Account.create(telegram_id: 123, username: 'test', first_name: 'f', last_name: 'l')

        assert_no_difference('TelegramCommon::Account.count') do
          @bot_service.start
        end

        telegram_account.reload

        assert_equal 'dhh', telegram_account.username
        assert_equal 'David', telegram_account.first_name
        assert_equal 'Haselman', telegram_account.last_name
      end

      should 'activate telegram account' do
        actual = TelegramCommon::Account.create(telegram_id: 123, active: false)

        assert_no_difference('TelegramCommon::Account.count') do
          @bot_service.start
        end

        actual.reload

        assert actual.active
      end
    end
  end

  context '/connect e@mail.com' do
    setup do
      @user = User.find(2)

      Intouch::TelegramBot.any_instance
        .expects(:send_message)
        .with(123, I18n.t('telegram_common.bot.connect.wait_for_email', email: @user.mail))

      @telegram_account = TelegramCommon::Account.create(telegram_id: 123)
      @telegram_message = ActionController::Parameters.new(
        from: { id:         123,
                username:   'dhh',
                first_name: 'David',
                last_name:  'Haselman' },
        chat: { id: 123 },
        text: "/connect #{@user.mail}"
      )

      @bot_service = Intouch::TelegramBot.new(@telegram_message)
    end

    should 'send connect instruction by email' do
      TelegramCommon::Mailer.any_instance
        .expects(:telegram_connect)
        .with(@user, @telegram_account)

      @bot_service.connect
    end
  end

  # setup do
  #   Intouch.stubs(:bot_token)
  #   Telegrammer::Bot.any_instance.stubs(:get_me)
  # end
  #
  # context '/start' do
  #   setup do
  #     @telegram_message = ActionController::Parameters.new(
  #       from: { id: 123,
  #               username: 'dhh',
  #               first_name: 'David',
  #               last_name: 'Haselman' },
  #       chat: { id: 123 },
  #       text: '/start'
  #     )
  #
  #     @bot_service = Intouch::TelegramBot.new(@telegram_message)
  #   end
  #
  #   context 'without user' do
  #     should 'create telegram account' do
  #       Intouch::TelegramBot.any_instance
  #         .expects(:send_message)
  #         .with(123, "Hello, David! I've added your profile for Redmine notifications.")
  #
  #       assert_difference('TelegramUser.count') do
  #         Intouch::TelegramBot.new(@telegram_message).start
  #       end
  #
  #       telegram_account = TelegramUser.last
  #       assert_equal 123, telegram_account.telegram_id
  #       assert_equal 'dhh', telegram_account.username
  #       assert_equal 'David', telegram_account.first_name
  #       assert_equal 'Haselman', telegram_account.last_name
  #       assert telegram_account.active
  #     end
  #
  #     should 'update telegram account' do
  #       Intouch::TelegramBot.any_instance
  #         .expects(:send_message)
  #         .with(123, "Hello, David! I've updated your profile for Redmine notifications.")
  #
  #       telegram_account = TelegramUser.create(telegram_id: 123, username: 'test', first_name: 'f', last_name: 'l')
  #
  #       assert_no_difference('TelegramUser.count') do
  #         Intouch::TelegramBot.new(@telegram_message).start
  #       end
  #
  #       telegram_account.reload
  #
  #       assert_equal 'dhh', telegram_account.username
  #       assert_equal 'David', telegram_account.first_name
  #       assert_equal 'Haselman', telegram_account.last_name
  #     end
  #
  #     should 'activate telegram account' do
  #       Intouch::TelegramBot.any_instance
  #         .expects(:send_message)
  #         .with(123, "Hello again, David! I've activated your profile for Redmine notifications.")
  #
  #       actual = TelegramUser.create(telegram_id: 123, active: false)
  #
  #       assert_no_difference('TelegramUser.count') do
  #         Intouch::TelegramBot.new(@telegram_message).start
  #       end
  #
  #       actual.reload
  #
  #       assert actual.active
  #     end
  #   end

  # context 'with user' do
  #   setup do
  #     Intouch::TelegramBot.any_instance
  #         .expects(:send_message)
  #         .with(123, I18n.t('redmine_2fa.redmine_telegram_connections.create.success'))
  #
  #     @user = User.find(2)
  #     @telegram_account = TelegramUser.create(telegram_id: 123, user_id: @user.id)
  #
  #     @bot_service.start
  #   end
  #
  #   should 'set telegram auth source' do
  #     @user.reload
  #     assert_equal auth_sources(:telegram), @user.auth_source
  #   end
  # end
  # end
end
