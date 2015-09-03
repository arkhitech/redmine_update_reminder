class RemindingMailer < ActionMailer::Base
  default from: Setting.mail_from

  def self.default_url_options
    Mailer.default_url_options
  end

  def reminder_email(user, issue)
    @user = user
    @issue = issue

    if IntouchSetting[:email_cc, @issue.project_id].present?
      mail(to: @user.mail, subject: @issue.subject, cc: IntouchSetting[:email_cc, @issue.project_id])
    else
      mail to: @user.mail, subject: @issue.subject
    end
  end
end
