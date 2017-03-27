module Intouch::Regular
  class RecipientsList
    def initialize(issue:, protocol:,  state:)
      @issue = issue
      @protocol = protocol
      @state = state
    end

    attr_reader :issue, :protocol, :state

  end
end