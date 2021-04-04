class RemindingMailer < ActionMailer::Base
  layout 'mailer'
  default from: Setting.mail_from
  helper :issues
  include Redmine::Utils::DateCalculation

  def self.default_url_options
    ::Mailer.default_url_options
  end
  
  def opt_out_email_addresses
    @opt_out_email_addresses ||= begin
      opt_out = Setting.plugin_redmine_update_reminder['opt_out']
      if opt_out.present? and opt_out != "none"
        User.joins("INNER JOIN custom_values ON users.id = custom_values.customized_id AND custom_field_id = #{opt_out} AND value = 0").map(&:mail)
      else
        []
      end
  
    end
  end
  private :opt_out_email_addresses

  def send_email(user, subject, message)
    @message = message
    unless user.locked?
      if opt_out_email_addresses.include? user.mail
        mail(subject: subject, cc: cc_email_addresses(user))
      else
        mail(to: user.mail, subject: subject, cc: cc_email_addresses(user))
      end
    end
  end
  private :send_email

  def cc_role_email_addresses(user)
    user_role_ids = Setting.plugin_redmine_update_reminder['user_roles']
    cc_role_ids = Setting.plugin_redmine_update_reminder['cc_roles']
    if cc_role_ids.present? and user_role_ids.present?
      projects = Project.active.joins(members: :member_roles).where("members.user_id" => user.id).where("member_roles.role_id" => user_role_ids)
      User.active.preload(:email_address).joins(members: :member_roles).where("#{Member.table_name}.project_id" => projects.pluck(:id)).
        where("#{MemberRole.table_name}.role_id IN (?)", cc_role_ids).map(&:email_address).map(&:address)
    else
      []
    end
  end
  private :cc_role_email_addresses

  def cc_email_addresses(user)
    return [] if non_working_week_days.include?(Date.today.cwday)
    cc_email_addresses = cc_role_email_addresses(user)    
    cc_email_addresses.uniq
    cc_email_addresses -= opt_out_email_addresses
    cc_email_addresses -= [user.mail]
  end
  private :cc_email_addresses
  
  # Public

  def reminder_inactivity_login(user, last_login)
    subject = I18n.t('update_reminder.subject', user_name: user.name)
    message = I18n.t('update_reminder.not_logged_since', user_name: user.firstname, last_login: distance_of_time_in_words(last_login, Time.now))
    send_email(user, subject, message)
  end

  def reminder_inactivity_updates(user, last_update)
    subject = I18n.t('update_reminder.subject', user_name: user.name)
    message = I18n.t('update_reminder.not_updated_since', user_name: user.firstname, last_login: distance_of_time_in_words(last_update, Time.now))
    send_email(user, subject, message)
  end

  def reminder_inactivity_notes (user, last_note)
    subject = I18n.t('update_reminder.subject', user_name: user.name)
    message = I18n.t('update_reminder.not_commented_since', user_name: user.firstname, last_note: distance_of_time_in_words(last_note, Time.now))
    send_email(user, subject, message)
  end

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
  
 def remind_user_past_due_issues(user, issues)
    @user = user
    @issues = issues
    
    subject = I18n.t('update_reminder.past_due_issue_update_required', 
      user_name: user.name, issue_count: @issues.count)
    mail(to: user.mail, subject: subject, cc: cc_email_addresses(user))
  end

 
end
