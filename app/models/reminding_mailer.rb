class RemindingMailer < ActionMailer::Base
  layout 'mailer'
  default from: Setting.mail_from
  helper :issues
  include Redmine::Utils::DateCalculation

  def self.default_url_options
    Mailer.default_url_options
  end
  
  def cc_email_addresses
    return '' if non_working_week_days.include?(Date.today.cwday)
    cc_group = Setting.plugin_redmine_update_reminder['cc']
    Group.includes(:users).find(cc_group).users.map(&:mail) if cc_group.present?
  end
  private :cc_email_addresses
  
  def reminder_issue_email(user, issue, updated_since)
    @user = user
    @issue = issue
    @updated_since = updated_since
        
    mail(to: @user.mail, subject: @issue.subject, cc: cc_email_addresses)
  end

  def reminder_status_email(user, issue, updated_since)
    @user = user
    @issue = issue
    @updated_since = updated_since

    mail(to: @user.mail, subject: @issue.subject, cc: cc_email_addresses)
  end
  
  def remind_user_issue_trackers(user, issues_with_updated_since)
    @user = user
    @issues_with_updated_since = issues_with_updated_since
    
    mail(to: @user.mail, subject: I18n.t('update_reminder.issue_tracker_update_required', 
      user_name: user.name, issue_count: @issues_with_updated_since.count), cc: cc_email_addresses)
  end

  def remind_user_issue_statuses(user, issues_with_updated_since)
    @user = user
    @issues_with_updated_since = issues_with_updated_since
    
    mail(to: @user.mail, subject: I18n.t('update_reminder.issue_status_update_required', 
      user_name: user.name, issue_count: @issues_with_updated_since.count), 
      cc: cc_email_addresses)
  end

  def remind_user_past_due_issues(user, issues)
    @user = user
    @issues = issues
    
    mail(to: @user.mail, subject: I18n.t('update_reminder.past_due_issue_update_required', 
      user_name: user.name, issue_count: @issues.count), 
      cc: cc_email_addresses)
  end

  def remind_user_issue_estimates(user, issues_with_updated_since)
    @user = user
    @issues_with_updated_since = issues_with_updated_since
    
    mail(to: @user.mail, subject: I18n.t('update_reminder.issue_estimate_required', 
      user_name: user.name, issue_count: @issues_with_updated_since.count), 
      cc: cc_email_addresses)
  end
  
end