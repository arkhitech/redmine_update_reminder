class TelegramGroupsController < ApplicationController
  unloadable

  layout 'admin'

  before_filter :require_admin

  def destroy
    TelegramGroupChat.find(params[:id]).destroy
    redirect_to action: 'plugin', id: 'redmine_intouch', controller: 'settings', tab: 'telegram'
  rescue
    flash[:error] = l(:error_unable_delete_telegram_group)
    redirect_to action: 'plugin', id: 'redmine_intouch', controller: 'settings', tab: 'telegram'
  end
end
