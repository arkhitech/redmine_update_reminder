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
      RemindingMailer.remind_user_past_due_issues(User.find(user_id), issues).deliver_now if issues.exists?
    end
  end
  
  def send_issue_status_reminders(issue_status_ids, mailed_issue_ids)
    Tracker.all.each do |tracker|
      issue_status_ids.each do |issue_status_id|
        update_duration = Setting.plugin_redmine_update_reminder["#{tracker.id}-status-#{issue_status_id}-update"].to_f      
        if update_duration > 0
          oldest_status_date = update_duration.days.ago
          issues_that_acquired_state_recently = JournalDetail.joins(journal: :issue).where(prop_key: "status_id", value: issue_status_id, "issues.tracker_id" => tracker).where("journals.created_on > ?", oldest_status_date).pluck("issues.id")
          issues = Issue.distinct.where(tracker_id: tracker.id, status_id: issue_status_id).where.not(id: (mailed_issue_ids.to_a + issues_that_acquired_state_recently).uniq)

          issues.find_each do |issue|       
            user = issue.assigned_to
            user = issue.author unless user
            updated_on = JournalDetail.joins(:journal).where("journals.journalized_id" => issue.id).where(prop_key: "status_id").maximum("journals.created_on")
            updated_on = issue.created_on unless updated_on
            RemindingMailer.reminder_status_email(user, issue, updated_on).deliver_now
            mailed_issue_ids << issue.id
          end
        end      
      end    
    end
  end
  
  def send_issue_tracker_reminders(issue_status_ids, mailed_issue_ids)
    trackers = Tracker.all
    
    trackers.each do |tracker|
      update_duration = Setting.plugin_redmine_update_reminder["#{tracker.id}_update_duration"].to_f
      if update_duration > 0
        
        updated_since = update_duration.days.ago
      	issues = Issue.where(tracker_id: tracker.id, status_id: issue_status_ids).
          where('updated_on < ?', updated_since).
          where.not(id: mailed_issue_ids.to_a)

        issues.find_each do |issue|
          user = issue.assigned_to
          user = issue.author unless user
          RemindingMailer.reminder_issue_email(user, issue, issue.updated_on).deliver_now
          mailed_issue_ids << issue.id
        end
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
      send_last_login_reminders(mailed_user_ids)
      send_last_update_reminders(mailed_user_ids)
      send_last_note_reminders(mailed_user_ids)
  end

  def send_issue_not_updated_reminders
      open_issue_status_ids = IssueStatus.where(is_closed: false).pluck('id')
      mailed_issue_ids = Set.new
      # Disabled
      # send_past_due_issues_reminders(open_issue_status_ids, mailed_issue_ids)
      send_issue_tracker_reminders(open_issue_status_ids, mailed_issue_ids)
      send_issue_status_reminders(open_issue_status_ids, mailed_issue_ids)
  end

 task send_all_reminders: :environment do
    prepare_locale
    send_user_inactivity_reminders
    send_issue_not_updated_reminders
  end
end
