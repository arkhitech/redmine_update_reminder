module Intouch
  module Patches
    module JournalPatch
      def self.included(base) # :nodoc:
        base.class_eval do
          unloadable

          after_create :handle_updated_issue

          private

          def handle_updated_issue
            Intouch::UpdatedIssueHandler.new(self).call
          end
        end
      end
    end
  end
end
Journal.send(:include, Intouch::Patches::JournalPatch)
