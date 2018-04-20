module Intouch
  class IssueUpdate
    attr_reader :issue, :journal

    def initialize(issue, journal, protocol_name)
      @issue, @journal, @protocol_name = issue, journal, protocol_name
    end

    def live_recipients
      @live_recipients ||= User.where(id: live_recipient_ids(@protocol_name)).select do |user|
        roles_in_issue = []
        roles_in_issue << 'assigned_to' if issue.assigned_to_id == user.id
        roles_in_issue << 'watchers' if issue.watchers.pluck(:user_id).include?(user.id) || IntouchSubscription.find_by(user_id: user.id, project_id: issue.project_id)&.active?
        roles_in_issue << 'author' if issue.author_id == user.id

        need_notification?(roles_in_issue)
      end
    end

    private

    def live_recipient_ids(protocol)
      settings = issue.project.send("active_#{protocol}_settings")
      return [] if settings.blank?
      recipients = settings.select { |k, _v| %w(author assigned_to watchers).include? k }

      subscribed_user_ids = IntouchSubscription.where(project_id: issue.project_id).select(&:active?).map(&:user_id)

      user_ids = []
      recipients.each_pair do |key, value|
        next unless value.try(:[], issue.status_id.to_s).try(:include?, issue.priority_id.to_s)
        case key
        when 'author'
          user_ids << issue.author.id
        when 'assigned_to'
          user_ids << issue.assigned_to_id if issue.assigned_to.class == User
        when 'watchers'
          user_ids += issue.watchers.pluck(:user_id)
        end
      end
      #  - [issue.updated_by.try(:id)]
      (user_ids.flatten + [issue.assigner_id] + subscribed_user_ids).uniq
    end

    def need_notification?(roles_in_issue)
      return roles_in_issue if required_recipients.blank?

      (roles_in_issue & required_recipients).present?
    end

    def required_recipients
      @required_recipients ||= Intouch::Live::Checker::Private.new(issue, issue.project).required_recipients
    end
  end
end
