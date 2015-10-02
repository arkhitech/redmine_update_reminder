module Intouch
  class HookListener < Redmine::Hook::ViewListener
    render_on :view_users_form, partial: 'settings/telegram_user'
  end
end
