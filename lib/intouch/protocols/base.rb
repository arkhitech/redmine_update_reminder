module Intouch::Protocols
  class Base
    def handle_update(update)
      raise NotImplementedError
    end

    def send_regular_notification(issue, state)
      raise NotImplementedError
    end

    protected

    def need_group_message?(journal)
      journal.blank? || (journal.details.pluck(:prop_key) & %w[priority_id status_id project_id]).present?
    end
  end
end
