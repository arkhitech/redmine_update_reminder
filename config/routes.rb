put 'intouch/save_settings' => 'intouch#save_settings'
resources :settings_templates

resources :sidekiq_cron_jobs do
  collection do
    get :init
  end
end
