require_relative '../checker/base'
require_relative '../message/private'
require_relative '../message/group'

module Intouch::Live::Handler
  class UpdatedIssue
    def initialize(journal)
      @journal = journal
      @issue = @journal.issue
      @project = @issue.project
    end

    def call
      return unless notification_required?

      send_private_messages
      send_group_messages
    end

    private

    attr_reader :issue, :project, :journal

    def notification_required?
      Intouch::Live::Checker::Base.new(issue, project).required?
    end

    def send_private_messages
      Intouch::Live::Message::Private.new(issue, project).send
    end

    def send_group_messages
      return unless need_group_message?

      Intouch::Live::Message::Group.new(issue, project).send
    end

    def need_group_message?
      (journal.details.pluck(:prop_key) & %w(priority_id status_id)).present?
    end
  end
end
