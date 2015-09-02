module Intouch

  class HookListener < Redmine::Hook::ViewListener
    render_on :view_users_form, partial: 'settings/telegram_user'
    # render_on :view_projects_form, partial: 'settings/project_intouch'

  end
end
