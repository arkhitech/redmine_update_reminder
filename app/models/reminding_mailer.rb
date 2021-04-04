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

  def user_inactivity_reminder(user, since, message)
    unless user.locked?
      subject = I18n.t('update_reminder.subject_user_inactivity', user_name: user.name)
      @message = I18n.t(message, user_name: user.firstname, since: distance_of_time_in_words(since, Time.now))
      if opt_out_email_addresses.include? user.mail
        mail(subject: subject, cc: cc_email_addresses(user))
      else
        mail(to: user.mail, subject: subject, cc: cc_email_addresses(user))
      end
    end
  end

 def issues_need_attention_reminder(user, issues, message)
    @user = user
    @issues = issues
    @message = I18n.t(message, user_name: user.firstname)
    subject = I18n.t('update_reminder.subject_issues_need_attention', 
      user_name: user.name, issue_count: @issues.count)

    if opt_out_email_addresses.include? user.mail
      mail(subject: subject, cc: cc_email_addresses(user))
    else
      mail(to: user.mail, subject: subject, cc: cc_email_addresses(user))
    end
  end

 
end
