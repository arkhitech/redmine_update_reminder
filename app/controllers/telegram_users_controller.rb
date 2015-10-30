class TelegramUsersController < ApplicationController
  unloadable if Rails.env.production?

  layout 'admin'

  before_filter :require_admin

  def edit
    @telegram_user = TelegramUser.find(params[:id])
  end

  def update
    @telegram_user = TelegramUser.find(params[:id])
    if @telegram_user.update_attributes(params[:telegram_user])
      flash[:notice] = l(:notice_successful_update)
      redirect_to controller: "telegram_users", action: 'edit', id: @telegram_user
    else
      render action: 'edit'
    end
  end

  def destroy
    TelegramUser.find(params[:id]).destroy
    redirect_to action: "plugin", id: "redmine_intouch", controller: "settings", tab: 'telegram'
  rescue
    flash[:error] = l(:error_unable_delete_telegram_user)
    redirect_to action: "plugin", id: "redmine_intouch", controller: "settings", tab: 'telegram'
  end

end
