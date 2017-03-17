module Intouch
  module Message
    class Regular
      extend ServiceInitializer

      attr_reader :issue

      delegate :title, :assigned_to, :priority, :status, :link,
               to: :formatter

      def initialize(issue)
        @issue = issue
      end

      def call
        [
          unassigned_message,
          overdue_message,
          without_due_date_message,
          inactive_message,
          basic_message
        ].compact.join("\n")
       end

      def basic_message
        <<~TEXT
          `#{title}`
          #{assigned_to}
          #{priority}
          #{status}
          #{link}
        TEXT
      end

      def unassigned_message
        I18n.t('intouch.telegram_message.issue.notice.unassigned') if issue.unassigned? || issue.assigned_to_group?
      end

      def overdue_message
        I18n.t('intouch.telegram_message.issue.notice.overdue') if issue.overdue?
      end

      def without_due_date_message
        I18n.t('intouch.telegram_message.issue.notice.without_due_date') if without_due_date?
      end

      def without_due_date?
        !issue.due_date.present? && issue.created_on < 1.day.ago
      end

      def inactive_message
        I18n.t('intouch.telegram_message.issue.inactive', hours: rounded_inactive_hours) if inactive?
      end

      def rounded_inactive_hours
        inactive_hours.round(1)
      end

      def inactive?
        return unless reminder_active? && reminder_interval.positive?

        inactive_hours >= reminder_interval
      end

      def inactive_hours
        @inactive_hours ||= ((Time.now - latest_action_on) / 3600)
      end

      def reminder_interval
        reminder_settings.try(:[], 'interval').to_i
      end

      def reminder_active?
        reminder_settings.try(:[], 'active')
      end

      def reminder_settings
        @reminder_settings ||= project.active_intouch_settings
          .try(:[], 'reminder_settings')
          .try(:[], issue.priority_id.to_s)
      end

      def latest_action_on
        latest_staff_action_on.present? ? latest_staff_action_on : issue.updated_on
      end

      def latest_staff_action_on
        @latest_assigner_update_on ||=
          issue.journals.order(:id).where(user_id: project.assigner_ids).last.try(:created_on)
      end

      def formatter
        @formatter ||= Formatter.new(issue)
      end

      def project
        @project ||= @issue.project
      end
    end
  end
end
