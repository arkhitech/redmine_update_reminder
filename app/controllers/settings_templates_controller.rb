class SettingsTemplatesController < ApplicationController
  unloadable

  layout 'admin'

  before_filter :require_admin

  accept_api_auth :index

  def index
    @settings_templates = SettingsTemplate.order(:name)

    respond_to do |format|
      format.api
      format.html { render :action => "index", :layout => false if request.xhr? }
    end

  end

  def new
    @settings_template = SettingsTemplate.new
    set_default_settings
  end

  def create
    @settings_template = SettingsTemplate.new(params[:settings_template])
    set_settings
    if @settings_template.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to :action => "plugin", :id => "redmine_intouch", :controller => "settings", :tab => 'settings_templates'
    else
      render :action => 'new'
    end
  end

  def edit
    @settings_template = SettingsTemplate.find(params[:id])
    set_default_settings
  end

  def update
    @settings_template = SettingsTemplate.find(params[:id])
    set_settings
    if @settings_template.update_attributes(params[:settings_template])
      flash[:notice] = l(:notice_successful_update)
      redirect_to :action => "plugin", :id => "redmine_intouch", :controller => "settings", :tab => 'settings_templates'
    else
      render :action => 'edit'
    end
  end

  def destroy
    SettingsTemplate.find(params[:id]).destroy
    redirect_to :action => "plugin", :id => "redmine_intouch", :controller => "settings", :tab => 'settings_templates'
  rescue
    flash[:error] = l(:error_unable_delete_settings_template)
    redirect_to :action => "plugin", :id => "redmine_intouch", :controller => "settings", :tab => 'settings_templates'
  end


  private

  def set_settings
    %w(alarm new working feedback overdue).each do |notice|
      %w(author assigned_to watchers).each do |receiver|
        set_settings_param("telegram_#{notice}_#{receiver}")
      end
      set_settings_param("telegram_#{notice}_telegram_groups", {})
      set_settings_param("telegram_#{notice}_user_groups", {})
    end
    set_settings_param('email_cc')
  end

  def set_default_settings
    %w(alarm new working feedback overdue).each do |notice|
      @settings_template.settings["telegram_#{notice}_telegram_groups"] = {} unless @settings_template.settings["telegram_#{notice}_telegram_groups"]
      @settings_template.settings["telegram_#{notice}_user_groups"] = {} unless @settings_template.settings["telegram_#{notice}_user_groups"]
    end
  end

  def set_settings_param(param, default = nil)
    @settings_template.settings[param] = params[param] ? params[param] : default
  end
end
