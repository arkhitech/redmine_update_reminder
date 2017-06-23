resources :settings_templates
get 'settings_templates/:copy_from/copy', to: 'settings_templates#new', as: 'copy_settings_template'

scope :intouch do
  put 'save_settings' => 'intouch#save_settings'

  post 'web_hook', to: IntouchHandlerController.action(:handle), as: :intouch_web_hook
  post 'bot_init' => 'intouch#bot_init', as: :intouch_bot_init
  delete 'bot_deinit' => 'intouch#bot_deinit', as: :intouch_bot_deinit
end

resources :telegram_groups, only: [:destroy]

resources :sidekiq_cron_jobs do
  collection do
    get :init
  end
end
