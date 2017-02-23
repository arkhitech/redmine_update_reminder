require_dependency 'projects_helper'

module Intouch
  module Patches
    module ProjectsHelperPatch
      def self.included(base)
        base.send(:include, MethodsPatch)

        base.module_eval do
          unloadable

          alias_method_chain :project_settings_tabs, :intouch
        end
      end

      module MethodsPatch
        def project_settings_tabs_with_intouch
          tabs = project_settings_tabs_without_intouch

          return tabs unless User.current.allowed_to?(:manage_intouch_settings, @project)

          tabs.push(
            name: 'intouch_settings',
            action: :manage_intouch_settings,
            partial: 'projects/settings/intouch/settings',
            label: 'intouch.label.settings'
          )

          tabs
        end
      end
    end
  end
end

ProjectsHelper.send(:include, Intouch::Patches::ProjectsHelperPatch)
