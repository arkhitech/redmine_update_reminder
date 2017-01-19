class IntouchController < ApplicationController
  unloadable

  before_filter :find_project

  def save_settings
    if request.put?
      @project.intouch_settings = params['intouch_settings']

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
end
