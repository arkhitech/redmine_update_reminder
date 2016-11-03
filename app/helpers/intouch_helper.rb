module IntouchHelper
  # Renders tabs and their content
  def render_intouch_tabs(settings_source, tabs, selected = params[:tab])
    if tabs.any?
      selected = nil unless tabs.detect { |tab| tab[:name] == selected }
      selected ||= tabs.first[:name]
      render partial: 'projects/settings/intouch/common/tabs',
             locals: { tabs: tabs, selected_tab: selected, settings_source: settings_source }
    else
      content_tag 'p', l(:label_no_data), class: 'nodata'
    end
  end
end
