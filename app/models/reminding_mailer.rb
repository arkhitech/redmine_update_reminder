class RemindingMailer < ActionMailer::Base
  default from: Setting.mail_from

  def self.default_url_options
    Mailer.default_url_options
  end

  def reminder_email(user_id, issue)
    @user = User.find user_id
    @issue = issue
    project = @issue.project

    email_cc =
        if project.settings_template_id.present?
          template = project.settings_template
          template.present? ? template.email_settings['cc'] : project.email_settings['cc']
        else
          project.email_settings['cc']
        end

    if email_cc.present?
      mail(to: @user.mail, subject: @issue.subject, cc: email_cc)
    else
      mail to: @user.mail, subject: @issue.subject
    end
  end
end
