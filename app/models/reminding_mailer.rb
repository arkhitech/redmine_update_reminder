class RemindingMailer < ActionMailer::Base
  default from: Setting.mail_from

  def self.default_url_options
    Mailer.default_url_options
  end

  def reminder_email(user, issue)
    @user = user
    @issue = issue

    email_cc = @issue.project.active_email_settings['cc']

    if email_cc.present?
      mail(to: @user.mail, subject: @issue.subject, cc: email_cc)
    else
      mail to: @user.mail, subject: @issue.subject
    end
  end
end
