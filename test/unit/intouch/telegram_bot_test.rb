require File.expand_path('../../../test_helper', __FILE__)

class Intouch::TelegramBotTest < ActiveSupport::TestCase
  fixtures :users, :email_addresses, :roles

  setup do
    Intouch.stubs(:bot_token)
    Telegrammer::Bot.any_instance.stubs(:get_me)
  end

  context 'group create' do
    setup do
      @telegram_message = ActionController::Parameters.new(
        from: { id:         123,
                username:   'abc',
                first_name: 'Antony',
                last_name:  'Brown' },
        chat: { id: -123,
                type: 'group', title: 'Test Group' },
        text: 'any message'
      )

      @bot_service = Intouch::TelegramBot.new(@telegram_message)
    end

    should 'create telegram group' do
      Intouch::TelegramBot.any_instance
        .expects(:send_message)
        .with(-123, I18n.t('intouch.bot.group.start.message'))

      assert_difference('TelegramGroupChat.count') do
        @bot_service.call
      end

      telegram_group = TelegramGroupChat.last

      assert_equal 'Test Group', telegram_group.title
      assert_equal 123, telegram_group.tid
    end
  end

  context '/start' do
    setup do
      @telegram_message = ActionController::Parameters.new(
        from: { id:         123,
                username:   'dhh',
                first_name: 'David',
                last_name:  'Haselman' },
        chat: { id: 123,
                type: 'private' },
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
          @bot_service.call
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
          @bot_service.call
        end

        telegram_account.reload

        assert_equal 'dhh', telegram_account.username
        assert_equal 'David', telegram_account.first_name
        assert_equal 'Haselman', telegram_account.last_name
      end

      should 'activate telegram account' do
        actual = TelegramCommon::Account.create(telegram_id: 123, active: false)

        assert_no_difference('TelegramCommon::Account.count') do
          @bot_service.call
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
        chat: { id: 123,
                type: 'private' },
        text: "/connect #{@user.mail}"
      )

      @bot_service = Intouch::TelegramBot.new(@telegram_message)
    end

    should 'send connect instruction by email' do
      TelegramCommon::Mailer.any_instance
        .expects(:telegram_connect)
        .with(@user, @telegram_account)

      @bot_service.call
    end
  end

  context '/update' do
    context 'private' do
      setup do
        Intouch::TelegramBot.any_instance
          .expects(:send_message)
          .with(123, I18n.t('intouch.bot.private.update.message'))

        @telegram_message = ActionController::Parameters.new(
          from: { id:         123,
                  username:   'abc',
                  first_name: 'Antony',
                  last_name:  'Brown' },
          chat: { id: 123,
                  type: 'private' },
          text: '/update'
        )

        @bot_service = Intouch::TelegramBot.new(@telegram_message)
      end

      should 'update telegram account' do
        telegram_account = TelegramCommon::Account.create(telegram_id: 123, username: 'test', first_name: 'f', last_name: 'l')

        assert_no_difference('TelegramCommon::Account.count') do
          @bot_service.call
        end

        telegram_account.reload

        assert_equal 'abc', telegram_account.username
        assert_equal 'Antony', telegram_account.first_name
        assert_equal 'Brown', telegram_account.last_name
      end
    end

    context 'group' do
      setup do
        Intouch::TelegramBot.any_instance
          .expects(:send_message)
          .with(-123, I18n.t('intouch.bot.group.update.message'))

        @telegram_message = ActionController::Parameters.new(
          from: { id:         123,
                  username:   'abc',
                  first_name: 'Antony',
                  last_name:  'Brown' },
          chat: { id: -123,
                  type: 'group', title: 'Updated!!!' },
          text: '/update'
        )

        @bot_service = Intouch::TelegramBot.new(@telegram_message)
      end

      should 'update telegram group' do
        telegram_group = TelegramGroupChat.create(tid: 123, title: 'test')

        assert_no_difference('TelegramGroupChat.count') do
          @bot_service.call
        end

        telegram_group.reload

        assert_equal 'Updated!!!', telegram_group.title
      end
    end
  end

  context '/help' do
    context 'private' do
      setup do
        @telegram_message = ActionController::Parameters.new(
          from: { id:         123,
                  username:   'abc',
                  first_name: 'Antony',
                  last_name:  'Brown' },
          chat: { id: 123,
                  type: 'private' },
          text: '/help'
        )

        @bot_service = Intouch::TelegramBot.new(@telegram_message)
      end

      should 'send help for private chat' do
        text = <<~TEXT
          /start - #{I18n.t('intouch.bot.private.help.start')}
          /connect - #{I18n.t('intouch.bot.private.help.connect')}
          /update - #{I18n.t('intouch.bot.private.help.update')}
          /help - #{I18n.t('intouch.bot.private.help.help')}
        TEXT

        Intouch::TelegramBot.any_instance.expects(:send_message).with(123, text.chomp)
        @bot_service.call
      end
    end

    context 'group' do
      setup do
        telegram_group = TelegramGroupChat.create(tid: 123, title: 'test')

        @telegram_message = ActionController::Parameters.new(
          from: { id:         123,
                  username:   'abc',
                  first_name: 'Antony',
                  last_name:  'Brown' },
          chat: { id: -123,
                  type: 'group' },
          text: '/help'
        )

        @bot_service = Intouch::TelegramBot.new(@telegram_message)
      end

      should 'send help for private chat' do
        text = <<~TEXT
          /update - #{I18n.t('intouch.bot.group.help.update')}
          /help - #{I18n.t('intouch.bot.group.help.help')}
        TEXT

        Intouch::TelegramBot.any_instance.expects(:send_message).with(-123, text.chomp)
        @bot_service.call
      end
    end
  end
end
