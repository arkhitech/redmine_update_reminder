class RemindingMailer < ActionMailer::Base
  default from: Setting.mail_from

  def self.default_url_options
    Mailer.default_url_options
  end

  def reminder_email(user, issue)
    @user = user
    @issue = issue

    email_cc =
        if IntouchSetting[:settings_template_id, @issue.project_id].present?
          template = SettingsTemplate.find_by id: IntouchSetting[:settings_template_id, @issue.project_id]
          template.present? ? template.email_cc : IntouchSetting[:email_cc, @issue.project_id]
        else
          IntouchSetting[:email_cc, @issue.project_id]
        end

    if email_cc.present?
      mail(to: @user.mail, subject: @issue.subject, cc: email_cc)
    else
      mail to: @user.mail, subject: @issue.subject
    end
  end
end
