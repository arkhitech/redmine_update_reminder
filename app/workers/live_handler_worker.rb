class LiveHandlerWorker
  include Sidekiq::Worker

  def perform(journal_id)
    journal = Journal.find_by(id: journal_id)
    Intouch::Live::Handler::UpdatedIssue.new(journal).call if journal
  end
end
