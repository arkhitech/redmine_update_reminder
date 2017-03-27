module Intouch::Regular::Checker
  class Base
    def initialize(issue:, state:, project:)
      @issue = issue
      @state = state
      @project = project
    end

    attr_reader :issue, :state, :project

    def required?
      notificable_for_state? &&
        (inactivity_notification? ? assigned_to_assigner? : true)
    end

    private

    def notificable_for_state?
      issue.notificable_for_state?(state)
    end

    def inactivity_notification?
      %w(feedback working).include?(state)
    end

    def assigned_to_assigner?
      project.assigner_ids.include?(issue.assigned_to_id)
    end
  end
end
