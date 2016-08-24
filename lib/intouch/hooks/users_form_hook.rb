module Intouch
  module Hooks
    class UsersFormHook < Redmine::Hook::ViewListener
      render_on :view_users_form, partial: 'settings/telegram_user'
    end
  end
end
