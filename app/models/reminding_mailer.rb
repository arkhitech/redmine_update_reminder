class RemindingMailer < ActionMailer::Base
  default from: Setting.mail_from

  def self.default_url_options
    Mailer.default_url_options
  end
  
  def reminder_issue_email(user, issue, update_duration)
    @user = user
    @issue = issue
    @update_duration = update_duration
    
    cc = Setting.plugin_redmine_update_reminder['cc']    
    cc = Group.includes(:users).find(cc).users.map(&:mail) if cc.present?
    
    mail(to: @user.mail, subject: @issue.subject, cc: cc)
  end

  def reminder_status_email(user, issue, update_duration)
    @user = user
    @issue = issue
    @update_duration = update_duration
    
    cc = Setting.plugin_redmine_update_reminder['cc']    
    cc = Group.includes(:users).find(cc).users.map(&:mail) if cc.present?
    
    mail(to: @user.mail, subject: @issue.subject, cc: cc)
  end
end