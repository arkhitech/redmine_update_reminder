class SettingsTemplate < ActiveRecord::Base
  unloadable

  attr_accessible :name, :intouch_settings

  store :intouch_settings, accessors: %w(assigner_groups reminder_settings telegram_settings email_settings)

  def copy_from(settings_template)
    self.attributes = settings_template.attributes.dup.except('id', 'created_on', 'updated_on')
    self.name += ' COPY'
    self
  end
end
