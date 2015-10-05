class AddIntouchSettingsToProjects < ActiveRecord::Migration
  def up
    add_column :projects, :intouch_settings, :text
    Project.reset_column_information
    IntouchSetting.joins(:project).group_by(&:project_id).each do |project_id, settings|
      project = Project.find project_id
      settings.each do |setting|
        project.intouch_settings[setting.name] = setting.value
      end
      project.save
    end
  end
  def down
    remove_column :projects, :intouch_settings
  end
end
