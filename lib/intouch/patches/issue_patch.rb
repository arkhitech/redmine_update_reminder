module Intouch
  module Patches
    module IssuePatch
      NOTIFICATION_STATES = %w(unassigned assigned_to_group overdue without_due_date working feedback)

      def self.included(base) # :nodoc:
        base.class_eval do
          unloadable

          # noinspection RubyArgCount
          store :intouch_data, accessors: %w(last_notification)

          after_commit :handle_new_issue, on: :create

          def self.alarms
            Issue.where(priority_id: IssuePriority.alarm_ids)
          end

          def self.working
            Issue.where(status_id: IssueStatus.working_ids)
          end

          def self.feedbacks
            Issue.where(status_id: IssueStatus.feedback_ids)
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

          def total_unassigned?
            unassigned? || assigned_to_group? || !project.assigner_ids.include?(assigned_to_id)
          end

          # This method need for `notification_states` and `notification_state`

          def without_due_date?
            !due_date.present? && created_on < 1.day.ago
          end

          def working?
            IssueStatus.working_ids.include? status_id
          end

          def feedback?
            IssueStatus.feedback_ids.include? status_id
          end

          def notification_state
            NOTIFICATION_STATES.select { |s| send("#{s}?") }.try :first
          end

          def notification_states
            NOTIFICATION_STATES.select { |s| send("#{s}?") }
          end

          def notificable_for_state?(state)
            case state
            when 'unassigned'
              notification_states.include?('unassigned') || notification_states.include?('assigned_to_group')
            when 'overdue'
              notification_states.include?('overdue') || notification_states.include?('without_due_date')
            when 'working'
              notification_states.include?('working')
            when 'feedback'
              notification_states.include?('feedback')
            else
              false
            end
          end

          def recipient_ids(protocol, state = notification_state)
            Intouch::Regular::RecipientsList.new(
              issue: self,
              state: state,
              protocol: protocol
            ).recipient_ids
          end

          def live_recipient_ids(protocol)
            settings = project.send("active_#{protocol}_settings")
            return [] if settings.blank?
            recipients = settings.select { |k, _v| %w(author assigned_to watchers).include? k }

            subscribed_user_ids = IntouchSubscription.where(project_id: project_id).select(&:active?).map(&:user_id)

            user_ids = []
            recipients.each_pair do |key, value|
              next unless value.try(:[], status_id.to_s).try(:include?, priority_id.to_s)
              case key
              when 'author'
                user_ids << author.id
              when 'assigned_to'
                user_ids << assigned_to_id if assigned_to.class == User
              when 'watchers'
                user_ids += watchers.pluck(:user_id)
              end
            end
            (user_ids.flatten + [assigner_id] + subscribed_user_ids - [updated_by.try(:id)]).uniq
          end

          def intouch_recipients(protocol, state = notification_state)
            Intouch::Regular::RecipientsList.new(
              issue: self,
              state: state,
              protocol: protocol
            ).call
          end

          def intouch_live_recipients(protocol)
            User.where(id: live_recipient_ids(protocol))
          end

          def performer
            assigned_to.present? ? assigned_to.name : I18n.t('intouch.telegram_message.issue.performer.unassigned')
          end

          def assigner_id
            if project.assigner_ids.include? assigned_to_id
              assigned_to_id
            else
              journals.order(:id).where(user_id: project.assigner_ids).last.try :user_id
            end
          end

          def bold_for_alarm(text)
            if alarm?
              "\n*#{I18n.t('field_priority')}: !!! #{text} !!!*"
            else
              "\n#{I18n.t('field_priority')}: #{text}"
            end
          end

          def telegram_message
            Intouch::Regular::Message::Base.new(self).base_message
          end

          private

          def handle_new_issue
            Intouch::Live::Handler::NewIssue.new(self).call
          end
        end
      end

      def last_journal
        @last_journal ||= journals.order(:id).last
      end
    end
  end
end
Issue.send(:include, Intouch::Patches::IssuePatch)
