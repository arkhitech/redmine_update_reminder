module Intouch
  module ProjectPatch
    def self.included(base) # :nodoc:
      base.class_eval do
        unloadable if Rails.env.production?

        # noinspection RubyArgCount
        store :intouch_settings,  accessors: %w(settings_template_id telegram_settings email_settings)

        after_create :copy_settings_from_parent

        def settings_template
          SettingsTemplate.find_by id: settings_template_id
        end

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
