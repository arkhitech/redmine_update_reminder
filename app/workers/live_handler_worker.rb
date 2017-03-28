class LiveHandlerWorker
  include Sidekiq::Worker

  def perform(journal_id)
    journal = Journal.find(journal_id)
    Intouch::Live::Handler::UpdatedIssue.new(journal).call
  end
end