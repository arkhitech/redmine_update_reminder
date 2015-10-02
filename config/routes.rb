put 'intouch/save_settings' => 'intouch#save_settings'
resources :settings_templates do
  collection do
    post :load
  end
end
