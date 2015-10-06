class RenameSettingsInSettingsTemplates < ActiveRecord::Migration
  def change
    rename_column :settings_templates, :settings, :intouch_settings
  end
end
