require_dependency 'projects_helper'
require_dependency 'intouch_helper'

module Intouch
  module Patches
    module ProjectsHelperPatch
      def project_settings_tabs
        tabs = super

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


ProjectsHelper.send(:prepend, Intouch::Patches::ProjectsHelperPatch)
ProjectsHelper.send(:include, IntouchHelper)
