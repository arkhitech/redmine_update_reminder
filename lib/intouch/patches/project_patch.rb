module Intouch
  module ProjectPatch
    def self.included(base) # :nodoc:
      base.class_eval do
        unloadable

        store :intouch_settings,  accessors: ['telegram_groups']

        after_create :copy_settings_from_parent

        def settings_template
          SettingsTemplate.find_by id: IntouchSetting['settings_template_id', id]
        end

        def group_settings(key)
          intouch_settings[key] || {}
        end

        def telegram_group_settings(telegram_group_id, status_id, priority_id)
          if telegram_groups and
              telegram_groups[telegram_group_id.to_s] and
              telegram_groups[telegram_group_id.to_s][status_id.to_s]
            telegram_groups[telegram_group_id.to_s][status_id.to_s].include? priority_id.to_s
          else
            nil
          end
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
