module RedmineUpdateReminder
  module Patches
    module UserPatch
      def self.included(base)
        
        base.class_eval do
          unloadable
          has_many :members, inverse_of: :user
        end
      end

    end
  end
end