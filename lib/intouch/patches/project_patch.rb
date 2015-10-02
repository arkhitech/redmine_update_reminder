module Intouch
  module ProjectPatch
    def self.included(base) # :nodoc:
      base.class_eval do
        unloadable

        after_create :copy_settings_from_parent

        private

        def copy_settings_from_parent
          if parent_id.present? and parent.present?
            ProjectSettingsCopier.perform_async(parent_id, id)
          end
        end

      end
    end

  end
end
Project.send(:include, Intouch::ProjectPatch)
