class RemindingMailer < ActionMailer::Base
  layout 'mailer'
  default from: Setting.mail_from
  helper :issues
  include Redmine::Utils::DateCalculation

  def self.default_url_options
    ::Mailer.default_url_options
  end
  
  def cc_group_email_addresses
    @cc_group_email_addresses ||= begin
      cc_group = Setting.plugin_redmine_update_reminder['cc']
      if cc_group.present?
        Group.includes(:users).find(cc_group).users.map(&:mail) 
      else
        []
      end
  
    end
  end
  private :cc_group_email_addresses

  def cc_role_email_addresses(user)
    cc_role_ids = Setting.plugin_redmine_update_reminder['cc_roles']
    if cc_role_ids.present?
      User.active.preload(:email_address).joins(members: :member_roles).where("#{Member.table_name}.project_id" => user.projects.pluck(:id)).
        where("#{MemberRole.table_name}.role_id IN (?)", cc_role_ids).map(&:email_address).map(&:address)
    else
      []
    end
  end

  def cc_email_addresses(user)
    return [] if non_working_week_days.include?(Date.today.cwday)
    cc_email_addresses = cc_group_email_addresses
    cc_email_addresses += cc_role_email_addresses(user)    
    cc_email_addresses.uniq
  end
  private :cc_email_addresses
  
  def reminder_issue_email(user, issue, updated_since)
    @user = user
    @issue = issue
    @updated_since = updated_since
        
    mail(to: @user.mail, subject: @issue.subject, cc: cc_email_addresses(user))
  end

  def reminder_status_email(user, issue, updated_since)
    @user = user
    @issue = issue
    @updated_since = updated_since

    mail(to: user.mail, subject: @issue.subject, cc: cc_email_addresses(user))
  end
  
  def remind_user_issue_trackers(user, issues_with_updated_since)
    @user = user
    @issues_with_updated_since = issues_with_updated_since
    subject = I18n.t('update_reminder.issue_tracker_update_required', 
      user_name: user.name, issue_count: @issues_with_updated_since.count)

    mail(to: user.mail, subject: subject, cc: cc_email_addresses(user))
  end

  def remind_user_issue_statuses(user, issues_with_updated_since)
    @user = user
    @issues_with_updated_since = issues_with_updated_since
    
    subject = I18n.t('update_reminder.issue_status_update_required', 
      user_name: user.name, issue_count: @issues_with_updated_since.count)
    mail(to: user.mail, subject: subject, cc: cc_email_addresses(user))
  end

  def remind_user_past_due_issues(user, issues)
    @user = user
    @issues = issues
    
    subject = I18n.t('update_reminder.past_due_issue_update_required', 
      user_name: user.name, issue_count: @issues.count)
    mail(to: user.mail, subject: subject, cc: cc_email_addresses(user))
  end

  def remind_user_issue_estimates(user, issues_with_updated_since)
    @user = user
    @issues_with_updated_since = issues_with_updated_since
    
    subject = I18n.t('update_reminder.issue_estimate_required', 
      user_name: user.name, issue_count: @issues_with_updated_since.count)
    mail(to: user.mail, subject: subject, cc: cc_email_addresses(user))
  end
  
end
