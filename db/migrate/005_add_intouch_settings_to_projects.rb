class AddIntouchSettingsToProjects < Rails.version < '5.0' ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]
  def up
    add_column :projects, :intouch_settings, :text
  end

  def down
    remove_column :projects, :intouch_settings
  end
end
