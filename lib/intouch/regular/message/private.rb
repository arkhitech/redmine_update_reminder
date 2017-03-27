module Intouch::Regular::Message
  class Private < Base
    def initialize(issue:, user:, state:, project:)
      @issue = issue
      @user = user
      @state = state
      @project = project
    end

    attr_reader :issue, :user, :state, :project

    def call
      message
    end

    def message
      prefix.present? ? "#{prefix}\n#{base_message}" : base_message
    end

    def prefix
      return nil unless settings.present?

      recipients_prefix
    end

    def recipients_prefix
      (roles_in_issue & recipients).map do |role|
        I18n.t("intouch.telegram_message.recipient.#{role}")
      end.join(', ')
    end

    def roles_in_issue
      roles_in_issue = []

      roles_in_issue << 'assigned_to' if issue.assigned_to_id == user.id
      roles_in_issue << 'watchers' if issue.watchers.pluck(:user_id).include? user.id
      roles_in_issue << 'author' if issue.author_id == user.id
      roles_in_issue
    end

    def recipients
      settings.select do |key, _value|
        %w(author assigned_to watchers).include?(key)
      end.keys
    end

    def settings
      @settings ||= project.active_telegram_settings.try(:[], state)
    end
  end
end
