put 'intouch/save_settings' => 'intouch#save_settings'
resources :settings_templates
resources :telegram_users, only: [:edit, :update, :destroy]

resources :sidekiq_cron_jobs do
  collection do
    get :init
  end
end
