# This file is a part of Redmine CRM (redmine_contacts) plugin,
# customer relationship management plugin for Redmine
#
# Copyright (C) 2011-2015 Kirill Bezrukov
# http://www.redminecrm.com/
#
# redmine_contacts is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_contacts is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_contacts.  If not, see <http://www.gnu.org/licenses/>.

require_dependency 'queries_helper'

module Intouch
  module Patches
    module ProjectsHelperPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable if Rails.env.production?

          alias_method_chain :project_settings_tabs, :intouch_settings
        end
      end

      module InstanceMethods
        def project_settings_tabs_with_intouch_settings
          tabs = project_settings_tabs_without_intouch_settings

          tabs.push({name: 'intouch_settings',
                     action: :manage_intouch_settings,
                     partial: 'projects/settings/intouch/settings',
                     label: 'intouch.label.settings'}) if User.current.allowed_to?(:manage_intouch_settings, @project)

          tabs
        end

        # Renders tabs and their content
        def render_intouch_tabs(tabs, selected=params[:tab])
          if tabs.any?
            unless tabs.detect { |tab| tab[:name] == selected }
              selected = nil
            end
            selected ||= tabs.first[:name]
            render partial: 'projects/settings/intouch/common/tabs', locals: {tabs: tabs, selected_tab: selected}
          else
            content_tag 'p', l(:label_no_data), class: "nodata"
          end
        end
      end

    end
  end
end

unless ProjectsHelper.included_modules.include?(Intouch::Patches::ProjectsHelperPatch)
  ProjectsHelper.send(:include, Intouch::Patches::ProjectsHelperPatch)
end
