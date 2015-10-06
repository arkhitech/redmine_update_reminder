class SettingsTemplate < ActiveRecord::Base
  unloadable

  attr_accessible :name, :intouch_settings

  store :intouch_settings, accessors: %w(telegram_settings email_settings)

end
