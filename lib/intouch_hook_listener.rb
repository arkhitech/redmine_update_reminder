class IntouchHookListener < Redmine::Hook::ViewListener
  render_on :view_users_form, partial: 'settings/telegram_user'
  # def view_users_form(context = {})
  #   context[:controller].send(:render_to_string, {
  #                                                  partial: "settings/telegram_user",
  #                                                  locals: context,
  #                                                  f: context[:f]
  #                                              })
  # end


end
