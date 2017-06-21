class IntouchController < ApplicationController
  unloadable

  before_filter :find_project, only: [:save_settings]

  skip_before_filter :check_if_login_required, only: [:web_hook]
  skip_before_action :verify_authenticity_token, only: [:web_hook]

  def save_settings
    if request.put?
      @project.intouch_settings = params['intouch_settings']

      @project.save

      flash[:notice] = l(:notice_successful_update)
    end

    redirect_to controller: 'projects', action: 'settings', tab: params[:tab] || 'intouch_settings', id: @project
  end

  def web_hook
    message = Telegram::Bot::Types::Update.new(params).message
    Intouch::TelegramBot.new(message).call if message.is_a?(Telegram::Bot::Types::Message)

    head :ok, content_type: 'text/html'
  end

  def bot_init
    bot = Telegram::Bot::Client.new(Intouch.bot_token)
    bot.api.setWebhook(url: Intouch.web_hook_url)

    redirect_to plugin_settings_path('redmine_intouch'), notice: t('intouch.bot.authorize.success')
  end

  def bot_deinit
    bot = Telegram::Bot::Client.new(Intouch.bot_token)
    bot.api.setWebhook(url: '')
    redirect_to plugin_settings_path('redmine_intouch'), notice: t('intouch.bot.deauthorize.success')
  end

  private

  def find_project
    project_id = params[:project_id]
    @project = Project.find(project_id)
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
