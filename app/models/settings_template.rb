class SettingsTemplate < ActiveRecord::Base
  unloadable if Rails.env.production?

  attr_accessible :name, :intouch_settings

  store :intouch_settings, accessors: %w(assigner_groups reminder_settings telegram_settings email_settings)

end
