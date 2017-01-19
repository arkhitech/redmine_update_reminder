class AddIntouchSettingsToProjects < ActiveRecord::Migration
  def up
    add_column :projects, :intouch_settings, :text
  end

  def down
    remove_column :projects, :intouch_settings
  end
end
