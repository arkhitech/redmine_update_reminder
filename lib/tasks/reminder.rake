namespace :redmine_update_reminder do
  require 'redmine/utils'
  include Redmine::Utils::DateCalculation

  def send_past_due_issues_reminders(issue_status_ids, mailed_issue_ids)
    users = Issue.where(status_id: issue_status_ids).where('due_date < ?', Date.today).
      where.not(assigned_to_id: nil).
      where.not(id: mailed_issue_ids.to_a).distinct.pluck(:assigned_to_id)
    users.find_all do |user_id|
      issues = Issue.where(status_id: issue_status_ids).where('due_date < ?', Date.today).
       where.(assigned_to_id: user_id)
      RemindingMailer.remind_user_past_due_issues(User.find(user_id), issues).deliver_now if issues.exists?
    end

    users = Issue.where(status_id: issue_status_ids).where('due_date < ?', Date.today).
      where(assigned_to_id: nil).
      where.not(id: mailed_issue_ids.to_a).distinct.pluck(:author_id)
    users.find_all do |user_id|
      issues = Issue.where(status_id: issue_status_ids).where('due_date < ?', Date.today).
        where(author_id: user_id)
      RemindingMailer.issues_need_attention_reminder(User.find(user_id), issues, 'update_reminder.past_due_issues').deliver_now if issues.exists?
      mailed_issue_ids.concat issues
    end
  end
  
  def send_issue_status_reminders(issue_status_ids, mailed_issue_ids)
    all_issues = []
    Tracker.all.each do |tracker|
      issue_status_ids.each do |issue_status_id|
        update_duration = Setting.plugin_redmine_update_reminder["#{tracker.id}-status-#{issue_status_id}-update"].to_f      
        if update_duration > 0
          oldest_status_date = update_duration.days.ago
          issues_that_acquired_state_recently = JournalDetail.joins(journal: :issue).where(prop_key: "status_id", value: issue_status_id, "issues.tracker_id" => tracker).where("journals.created_on > ?", oldest_status_date).pluck("issues.id")
          all_issues = Issue.distinct.where(tracker_id: tracker.id, status_id: issue_status_id).
            where(project_id: Project.active.pluck(:id)).
            where.not(id: (mailed_issue_ids.to_a + issues_that_acquired_state_recently).uniq)
        end
      end
    end
    
    User.active.each do |user|
      issues = Issue.where(id: all_issues, assigned_to_id: user.id)
      issues = issues.or Issue.where(id: all_issues, assigned_to_id: nil, author_id: user.id)
      RemindingMailer.issues_need_attention_reminder(user, issues, 'update_reminder.tracker_status_reminder').deliver_now if issues.exists?
      mailed_issue_ids.concat issues
    end
  end
  
  def send_issue_tracker_reminders(issue_status_ids, mailed_issue_ids)
    all_issues = []
    Tracker.all.each do |tracker|
      update_duration = Setting.plugin_redmine_update_reminder["#{tracker.id}_update_duration"].to_f
      if update_duration > 0
        updated_since = update_duration.days.ago
        all_issues << Issue.where(tracker_id: tracker.id, status_id: issue_status_ids).
          where(project_id: Project.active.pluck(:id)).
          where('updated_on < ?', updated_since).
          where.not(id: mailed_issue_ids.to_a).
          pluck(:id)
      end
    end

    User.active.each do |user|
      issues = Issue.where(id: all_issues, assigned_to_id: user.id)
      issues = issues.or Issue.where(id: all_issues, assigned_to_id: nil, author_id: user.id)
      RemindingMailer.issues_need_attention_reminder(user, issues, 'update_reminder.tracker_reminder').deliver_now if issues.exists?
      mailed_issue_ids.concat issues
    end
  end
  
  def send_never_logged_in_reminders(exclude_user_ids)
    max_inactivity = Setting.plugin_redmine_update_reminder["days_since_last_login"].to_i
    interval = Setting.plugin_redmine_update_reminder["notification_interval"].to_i
    interval = 1 if interval == 0
    max_notifications = Setting.plugin_redmine_update_reminder["number_of_notifications"].to_i
    
    created_on = User.arel_table[:created_on]
    users = User.active.where(:last_login_on => nil).where(created_on.lt(max_inactivity.days.ago)).where.not(id: exclude_user_ids.to_a)
    
    users.find_all do |user|
      difference = Date.today - user.created_on.to_date
      if difference % interval == 0 and (max_notifications == 0 or difference / interval < max_notifications)
        RemindingMailer.user_inactivity_reminder(user, user.created_on, 'update_reminder.not_logged_since').deliver_now
        exclude_user_ids << user.id
      end
    end
  end

  def send_last_login_reminders(exclude_user_ids)
    max_inactivity = Setting.plugin_redmine_update_reminder["days_since_last_login"].to_i
    interval = Setting.plugin_redmine_update_reminder["notification_interval"].to_i
    interval = 1 if interval == 0
    max_notifications = Setting.plugin_redmine_update_reminder["number_of_notifications"].to_i
    if max_inactivity > 0
      last_login_on = User.arel_table[:last_login_on]
      users = User.where(last_login_on.lt(max_inactivity.days.ago)).where.not(id: exclude_user_ids.to_a)

      users.find_all do |user|
        difference = Date.today - max_inactivity - user.last_login_on.to_date
        if difference % interval == 0 and (max_notifications == 0 or difference / interval < max_notifications)
          RemindingMailer.user_inactivity_reminder(user, user.last_login_on, 'update_reminder.not_logged_since').deliver_now
          exclude_user_ids << user.id
        end
      end
    end
  end

  def send_last_update_reminders(exclude_user_ids)
    max_inactivity = Setting.plugin_redmine_update_reminder["days_since_last_update"].to_i
    interval = Setting.plugin_redmine_update_reminder["notification_interval"].to_i
    interval = 1 if interval == 0
    max_notifications = Setting.plugin_redmine_update_reminder["number_of_notifications"].to_i
    if max_inactivity > 0 
      created_on = Journal.arel_table[:created_on]
      issue_created_on = Issue.arel_table[:created_on]
      issue_authors = Issue.where(issue_created_on.gt(max_inactivity.days.ago)).distinct.pluck(:author_id) 
      issue_previous_authors = JournalDetail.joins(:journal).where(prop_key: "author_id").where(created_on.gt(max_inactivity.days.ago)).distinct.pluck(:old_value).map(&:to_i)
      journal_authors = Journal.where(created_on.gt(max_inactivity.days.ago)).distinct.pluck(:user_id)
      users = User.where.not(id: (issue_authors+issue_previous_authors+journal_authors+exclude_user_ids).uniq)
      users.each do |user| 
        last_update = Journal.where(user_id: user.id).maximum(:created_on)
        last_update = user.created_on unless last_update
        difference = Date.today - max_inactivity - last_update.to_date
        if difference % interval == 0 and (max_notifications == 0 or difference / interval < max_notifications)
          RemindingMailer.user_inactivity_reminder(user, last_update, 'update_reminder.not_updated_since').deliver_now
          exclude_user_ids << user.id
        end
      end
    end
  end

  def send_last_note_reminders(exclude_user_ids)
    max_inactivity = Setting.plugin_redmine_update_reminder["days_since_last_note"].to_i
    interval = Setting.plugin_redmine_update_reminder["notification_interval"].to_i
    interval = 1 if interval == 0
    max_notifications = Setting.plugin_redmine_update_reminder["number_of_notifications"].to_i
    if max_inactivity > 0
      created_on = Journal.arel_table[:created_on]
      note_authors = Journal.where.not(notes: nil).where(created_on.gt(max_inactivity.days.ago)).distinct.pluck(:user_id)
      
      users = User.where.not(id: (note_authors+exclude_user_ids).uniq)
      users.each do |user| 
        last_note = Journal.where(user_id: user.id).where.not(notes: nil).maximum(:created_on)
        last_note = user.created_on unless last_note
        difference = Date.today - max_inactivity - last_note.to_date
        if difference % interval == 0 and (max_notifications == 0 or difference / interval < max_notifications)
          RemindingMailer.user_inactivity_reminder(user, last_note, 'update_reminder_not_commented_since').deliver_now
          exclude_user_ids << user.id
        end
      end
    end
  end

  def prepare_locale
     include ActionView::Helpers::DateHelper
    ::I18n.locale = Setting.default_language
  end

  def send_user_inactivity_reminders
      mailed_user_ids = []
      send_never_logged_in_reminders(mailed_user_ids)
      send_last_login_reminders(mailed_user_ids)
      send_last_update_reminders(mailed_user_ids)
      send_last_note_reminders(mailed_user_ids)
  end

  def send_issue_not_updated_reminders
      open_issue_status_ids = IssueStatus.where(is_closed: false).pluck('id')
      mailed_issue_ids = []
      # Disabled
      # send_past_due_issues_reminders(open_issue_status_ids, mailed_issue_ids)
      send_issue_tracker_reminders(open_issue_status_ids, mailed_issue_ids)
      send_issue_status_reminders(open_issue_status_ids, mailed_issue_ids)
  end

  def send_statistics
    max_inactivity_login = Setting.plugin_redmine_update_reminder["days_since_last_login"].to_i
    max_inactivity_update = Setting.plugin_redmine_update_reminder["days_since_last_update"].to_i
    user_role_ids = Setting.plugin_redmine_update_reminder['user_roles'] 
    supervisor_role_ids = Setting.plugin_redmine_update_reminder['cc_roles'] 
    user_role_names = Role.where(:id => user_role_ids).pluck(:name)
    Project.active.each do |p|
      # Last login
      last_login_on = User.arel_table[:last_login_on]
      logged_in_users = User.active.where(last_login_on.gt(max_inactivity_login.days.ago)).joins(members: :member_roles).where("#{Member.table_name}.project_id" => p.id).where("#{MemberRole.table_name}.role_id IN (?)", user_role_ids) 

      # Last interaction
      supervisors = User.active.joins(members: :member_roles).where("#{Member.table_name}.project_id" => p.id).where("#{MemberRole.table_name}.role_id IN (?)", supervisor_role_ids)
      interacting_users = []
      if supervisors.count > 0
        f = Redmine::Activity::Fetcher.new(supervisors.first, :project => p, :with_subprojects => 1) 
        f.scope = ["issues"] 
        interacting_users = f.events(DateTime.now - max_inactivity_update.days, DateTime.now ).map {|e| defined?(e.user_id) ? e.user_id : e.author_id}
        interacting_users = interacting_users.uniq
        if logged_in_users.count + interacting_users.count > 0
          RemindingMailer.statistics(p, supervisors, "Proyecto #{p.name}: #{logged_in_users.count} usuarios con rol #{user_role_names} han accedido en los últimos #{max_inactivity_login} días y #{interacting_users.count} usuarios han anotado algo en los últimos #{max_inactivity_update} días").deliver_now
        end
      end
    end
  end

 task send_all_reminders: :environment do
    prepare_locale
    send_user_inactivity_reminders
    send_issue_not_updated_reminders
    send_statistics
  end
end
