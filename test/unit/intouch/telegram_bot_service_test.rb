require File.expand_path('../../../test_helper', __FILE__)

class Intouch::TelegramBotServiceTest < ActiveSupport::TestCase
  fixtures :users, :email_addresses, :roles, :auth_sources

  setup do
    Intouch.stubs(:bot_token)
    Telegrammer::Bot.any_instance.stubs(:get_me)
  end

  context '/start' do
    setup do
      @telegram_message = ActionController::Parameters.new(
        from: { id: 123,
                username: 'dhh',
                first_name: 'David',
                last_name: 'Haselman' },
        chat: { id: 123 },
        text: '/start'
      )

      @bot_service = Intouch::Service::TelegramBot.new(@telegram_message)
    end

    context 'without user' do
      should 'create telegram account' do
        Intouch::Service::TelegramBot.any_instance
          .expects(:send_message)
          .with(123, "Hello, David! I've added your profile for Redmine notifications.")

        assert_difference('TelegramUser.count') do
          Intouch::Service::TelegramBot.new(@telegram_message).start
        end

        telegram_account = TelegramUser.last
        assert_equal 123, telegram_account.tid
        assert_equal 'dhh', telegram_account.username
        assert_equal 'David', telegram_account.first_name
        assert_equal 'Haselman', telegram_account.last_name
        assert telegram_account.active
      end

      should 'update telegram account' do
        Intouch::Service::TelegramBot.any_instance
          .expects(:send_message)
          .with(123, "Hello, David! I've updated your profile for Redmine notifications.")

        telegram_account = TelegramUser.create(tid: 123, username: 'test', first_name: 'f', last_name: 'l')

        assert_no_difference('TelegramUser.count') do
          Intouch::Service::TelegramBot.new(@telegram_message).start
        end

        telegram_account.reload

        assert_equal 'dhh', telegram_account.username
        assert_equal 'David', telegram_account.first_name
        assert_equal 'Haselman', telegram_account.last_name
      end

      should 'activate telegram account' do
        Intouch::Service::TelegramBot.any_instance
          .expects(:send_message)
          .with(123, "Hello again, David! I've activated your profile for Redmine notifications.")

        actual = TelegramUser.create(tid: 123, active: false)

        assert_no_difference('TelegramUser.count') do
          Intouch::Service::TelegramBot.new(@telegram_message).start
        end

        actual.reload

        assert actual.active
      end
    end

    # context 'with user' do
    #   setup do
    #     Intouch::Service::TelegramBot.any_instance
    #         .expects(:send_message)
    #         .with(123, I18n.t('redmine_2fa.redmine_telegram_connections.create.success'))
    #
    #     @user = User.find(2)
    #     @telegram_account = TelegramUser.create(tid: 123, user_id: @user.id)
    #
    #     @bot_service.start
    #   end
    #
    #   should 'set telegram auth source' do
    #     @user.reload
    #     assert_equal auth_sources(:telegram), @user.auth_source
    #   end
    # end
  end

end
