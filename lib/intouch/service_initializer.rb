# frozen_string_literal: true
module Intouch
  module ServiceInitializer
    def call(*args)
      new(*args).call
    end
  end
end
