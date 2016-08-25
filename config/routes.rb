put 'intouch/save_settings' => 'intouch#save_settings'
resources :settings_templates
get 'settings_templates/:copy_from/copy', to: 'settings_templates#new', as: 'copy_settings_template'

resources :telegram_users, only: [:edit, :update, :destroy]
resources :telegram_groups, only: [:destroy]

resources :sidekiq_cron_jobs do
  collection do
    get :init
  end
end
