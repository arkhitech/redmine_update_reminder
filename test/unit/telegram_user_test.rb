require File.expand_path('../../test_helper', __FILE__)

class TelegramUserTest < ActiveSupport::TestCase

  def test_name
    telegram_user = TelegramUser.new first_name: 'Bob', last_name: 'Marley'
    assert telegram_user.name, 'Bob Marley'

    telegram_user.username = 'bob_marley'

    assert_equal telegram_user.name, 'Bob Marley @bob_marley'
  end

  def test_activate
    telegram_user = TelegramUser.create first_name: 'Bob', last_name: 'Marley'
    assert_equal telegram_user.active, true

    telegram_user.activate
    assert_equal telegram_user.active, true

    telegram_user.deactivate
    assert_equal telegram_user.active, false

    telegram_user.activate
    assert_equal telegram_user.active, true
  end
end
