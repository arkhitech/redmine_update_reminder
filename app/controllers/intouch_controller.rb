class IntouchController < ApplicationController
  unloadable

  before_filter :find_project

  def save_settings
    if request.put?
      set_settings

      @project.save

      flash[:notice] = l(:notice_successful_update)
    end

    redirect_to controller: 'projects', action: 'settings', tab: params[:tab] || 'intouch_settings', id: @project
  end

  private

  def find_project
    project_id = params[:project_id]
    @project = Project.find(project_id)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def set_settings
    %w(telegram email).each do |protocol|
      %w(alarm new working feedback overdue).each do |notice|
        %w(author assigned_to watchers).each do |receiver|
          set_settings_param "#{protocol}_#{notice}_#{receiver}"
        end
        set_settings_param "#{protocol}_#{notice}_user_groups"
      end
    end
    set_settings_param('telegram_groups')
    set_settings_param('settings_template_id')
    set_settings_param('email_cc')
  end

  def set_settings_param(param)
    @project.intouch_settings[param] = params[param]
  end
end
