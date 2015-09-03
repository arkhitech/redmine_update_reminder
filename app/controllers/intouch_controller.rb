class IntouchController < ApplicationController
  unloadable

  before_filter :find_project

  def save_settings
    if request.put?
      set_settings

      flash[:notice] = l(:notice_successful_update)
    end

    redirect_to controller: 'projects', action: 'settings', tab: params[:tab] || 'intouch', id: @project
  end

  private

  def find_project
    project_id = params[:project_id]
    @project = Project.find(project_id)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def set_settings
    %w(alarm new wip feedback overdue).each do |notice|
      %w(author assigned_to watchers).each do |receiver|
        set_settings_param("telegram_#{notice}_#{receiver}".to_sym)
      end
      set_settings_param("telegram_#{notice}_telegram_groups".to_sym)
      set_settings_param("telegram_#{notice}_user_groups".to_sym)
    end
    set_settings_param(:email_cc)
  end

  def set_settings_param(param)
    IntouchSetting[param, @project.id] = params[param] if params[param]
  end
end
