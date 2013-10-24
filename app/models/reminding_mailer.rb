class RemindingMailer < ActionMailer::Base
  default from: Setting.mail_from

  def self.default_url_options
    Mailer.default_url_options
  end
  
  def reminder_email(user,issue)
    @user=user
    @issue=issue
    mail(to: @user.mail, subject: @issue.subject, cc: Setting.plugin_redmine_update_reminder['cc'] )
  end
end