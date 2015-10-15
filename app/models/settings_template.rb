class SettingsTemplate < ActiveRecord::Base
  unloadable if Rails.env.production?

  attr_accessible :name, :intouch_settings

  store :intouch_settings, accessors: %w(reminder_settings telegram_settings email_settings)

end
