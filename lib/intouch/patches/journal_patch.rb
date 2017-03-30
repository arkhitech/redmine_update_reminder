module Intouch
  module Patches
    module JournalPatch
      def self.included(base) # :nodoc:
        base.class_eval do
          unloadable

          after_commit :handle_updated_issue, on: :create

          private

          def handle_updated_issue
            LiveHandlerWorker.perform_in(5.seconds, id)
          end
        end
      end
    end
  end
end
Journal.send(:include, Intouch::Patches::JournalPatch)
