class RemindingMailer < ActionMailer::Base
  default from: 'no_reply@task_reminder_plugin'
  def reminder_email(user,issue)
    @user=user
    @issue=issue
    mail(to: @user.mail, subject: @issue.subject, cc: Setting.plugin_task_reminder['cc'] )
  end
end