module Intouch
  module IssuePatch
    def self.included(base) # :nodoc:
      base.class_eval do
        unloadable if Rails.env.production?

        # noinspection RubyArgCount
        store :intouch_data, accessors: %w(last_notification)

        before_save :check_alarm
        after_create :send_new_message

        def self.alarms
          Issue.where(priority_id: IssuePriority.alarm_ids)
        end

        def self.working
          Issue.where(status_id: IssueStatus.working_ids)
        end

        def self.feedbacks
          Issue.where(status_id: IssueStatus.feedback_ids)
        end

        def last_assigner_id
          journals.where(user_id: project.assigner_ids).last.try :user_id
        end

        def assigners_updated_on
          assigners_updated_on = journals.where(user_id: project.assigner_ids).last.try :created_on
          assigners_updated_on.present? ? assigners_updated_on : updated_on
        end

        def alarm?
          IssuePriority.alarm_ids.include? priority_id
        end

        def unassigned?
          assigned_to.nil?
        end

        def assigned_to_group?
          assigned_to.class == Group
        end

        def working?
          IssueStatus.working_ids.include? status_id
        end

        def feedback?
          IssueStatus.feedback_ids.include? status_id
        end

        def without_due_date?
          !due_date.present? and created_on < 1.day.ago
        end

        def notification_state
          %w(unassigned assigned_to_group overdue without_due_date working feedback).select { |s| send("#{s}?") }.try :first
        end

        def recipient_ids(protocol, state = notification_state)
          if project.send("active_#{protocol}_settings") && state && project.send("active_#{protocol}_settings")[state]
            project.send("active_#{protocol}_settings")[state].map do |key, value|
              case key
                when 'author'
                  author.id
                when 'assigned_to'
                  if assigned_to.class == Group
                    assigned_to.user_ids
                  else
                    assigned_to_id if project.assigner_ids.include?(assigned_to_id)
                  end
                when 'watchers'
                  watchers.pluck(:user_id)
                when 'user_groups'
                  Group.where(id: value).map(&:user_ids).flatten if value.present?
                else
                  nil
              end
            end.flatten.uniq + [last_assigner_id]
          end
        end

        def live_recipient_ids(protocol)
          settings = project.send("active_#{protocol}_settings")
          if settings.present?
            recipients = settings.select { |k, v| %w(author assigned_to watchers).include? k }

            user_ids = []
            recipients.each_pair do |key, value|
              if value.try(:[], status_id.to_s).try(:include?, priority_id.to_s)
                case key
                  when 'author'
                    user_ids << author.id
                  when 'assigned_to'
                    if assigned_to.class == Group
                      user_ids += assigned_to.user_ids
                    else
                      user_ids << assigned_to_id if project.assigner_ids.include?(assigned_to_id)
                    end
                  when 'watchers'
                    user_ids += watchers.pluck(:user_id)
                  else
                    nil
                end
              end
            end
            user_ids.flatten.uniq + [last_assigner_id] - [updated_by.try(:id)] # Не отправляем сообщение тому, то обновил задачу
          else
            []
          end
        end

        def intouch_recipients(protocol, state = notification_state)
          User.where(id: recipient_ids(protocol, state))
        end

        def intouch_live_recipients(protocol)
          User.where(id: live_recipient_ids(protocol))
        end

        def performer
          assigned_to.present? ? assigned_to.name : I18n.t('intouch.telegram_message.issue.performer.unassigned')
        end

        def inactive?
          interval = project.active_intouch_settings.
              try(:[], 'working').try(:[], 'priority_notification').
              try(:[], "#{priority_id}").try(:[], 'interval')
          interval.present? and updated_on < interval.to_i.hours.ago
        end

        def inactive_message
          hours = ((Time.now - updated_on) / 3600).round(1)
          I18n.t 'intouch.telegram_message.issue.inactive', hours: hours
        end

        def updated_by
          journals.last.user if journals.present?
        end

        def updated_details
          last_journal = journals.last
          updated_details = []
          if last_journal.present?
            updated_details = last_journal.visible_details.map{|detail| detail.prop_key.to_s.gsub(/_id$/, '')}
            updated_details << 'notes' if last_journal.notes.present?
          end
          updated_details
        end

        def updated_details_text
          if updated_details.present?
            (updated_details - %w(priority status assigned_to)).map do |field|
              I18n.t(('field_' + field).to_sym)
            end.join(', ')
          end
        end

        def updated_priority_text
          if updated_details.include?('priority')
            last_journal = journals.last
            priority_journal = last_journal.details.find_by(prop_key: 'priority_id')
            old_priority = IssuePriority.find priority_journal.old_value
            "#{old_priority.name} -> #{priority.name}"
          else
            priority.name
          end
        end

        def updated_status_text
          if updated_details.include?('status')
            last_journal = journals.last
            status_journal = last_journal.details.find_by(prop_key: 'status_id')
            old_status = IssueStatus.find status_journal.old_value
            "#{old_status.name} -> #{status.name}"
          else
            status.name
          end
        end

        def updated_performer_text
          if updated_details.include?('assigned_to')
            last_journal = journals.last
            performer_journal = last_journal.details.find_by(prop_key: 'assigned_to_id')
            if performer_journal.old_value
              old_performer = Principal.find performer_journal.old_value
              "#{old_performer.name} -> #{performer}"
            else
              "#{I18n.t('intouch.telegram_message.issue.performer.unassigned')} -> #{performer}"
            end
          else
            assigned_to.name
          end
        end

        def telegram_live_message
          message = <<TEXT
#{I18n.t('field_priority')}: #{updated_priority_text}
#{I18n.t('field_status')}: #{updated_status_text}
#{I18n.t('field_assigned_to')}: #{updated_performer_text}
#{project.name}: #{subject}
#{Intouch.issue_url(id)}
TEXT
          message = "#{I18n.t('intouch.telegram_message.issue.updated_details')}: #{updated_details_text}\n#{message}" if updated_details_text.present?
          message = "#{I18n.t('intouch.telegram_message.issue.updated_by')}: #{updated_by}\n#{message}" if updated_by.present?
          message
        end

        def telegram_message
          message = <<TEXT
#{I18n.t('field_priority')}: #{priority.try :name}
#{I18n.t('field_status')}: #{status.try :name}
#{I18n.t('field_assigned_to')}: #{performer}
#{project.name}: #{subject}
#{Intouch.issue_url(id)}
TEXT
          message = "#{inactive_message}\n#{message}" if inactive?
          message = "*** #{I18n.t('intouch.telegram_message.issue.notice.without_due_date')} *** \n#{message}" if without_due_date?
          message = "*** #{I18n.t('intouch.telegram_message.issue.notice.overdue')} ***  \n#{message}" if overdue?
          message = "*** #{I18n.t('intouch.telegram_message.issue.notice.unassigned')} *** \n#{message}" if unassigned? or assigned_to_group?
          message
        end

        private

        def check_alarm
          if !new_record? and project.module_enabled?(:intouch) and project.active? and !closed?
            if alarm? or Intouch.work_time?
              if Intouch.active_protocols.include? 'telegram'

                if changed_attributes and (changed_attributes['priority_id'] or changed_attributes['status_id'])
                  IntouchSender.send_live_telegram_group_message(id, status_id, priority_id)
                end

                IntouchSender.send_live_telegram_message(id)
              end

              IntouchSender.send_live_email_message(id) if Intouch.active_protocols.include? 'email'
            end
          end
        end

        def send_new_message
          if project.module_enabled?(:intouch) and project.active? and !closed?
            if Intouch.active_protocols.include? 'telegram'
              IntouchSender.send_live_telegram_message(id)
              IntouchSender.send_live_telegram_group_message(id, status_id, priority_id)
            end

            IntouchSender.send_live_email_message(id) if Intouch.active_protocols.include? 'email'
          end
        end

      end
    end

  end
end
Issue.send(:include, Intouch::IssuePatch)
