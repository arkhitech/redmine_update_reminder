class ProjectSettingsCopier
  include Sidekiq::Worker

  def perform(parent_project_id, project_id)
    IntouchSetting.where(project_id: parent_project_id).each do |setting|
      IntouchSetting[setting.name, project_id] = setting.value
    end
  end

end
