class RenameSettingsInSettingsTemplates < Rails.version < '5.0' ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]
  def change
    rename_column :settings_templates, :settings, :intouch_settings
  end
end
