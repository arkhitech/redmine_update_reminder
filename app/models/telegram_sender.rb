class TelegramSender
  unloadable

  def self.send_alarm_message(project_id, issue_id)
    send_message('alarm', project_id, issue_id)
  end

  def self.send_new_message(project_id, issue_id)
    send_message('new', project_id, issue_id)
  end
  def self.send_overdue_message(project_id, issue_id)
    send_message('overdue', project_id, issue_id)
  end

  def self.send_working_message(project_id, issue_id)
    send_message('working', project_id, issue_id)
  end

  def self.send_feedback_message(project_id, issue_id)
    send_message('feedback', project_id, issue_id)
  end

  def self.send_message(notice, project_id, issue_id)
    TelegramSenderWorker.perform_in(5.seconds, notice, project_id, issue_id)
  end
end
