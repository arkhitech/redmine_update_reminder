module IntouchHelper
  # Renders tabs and their content
  def render_intouch_tabs(tabs, selected=params[:tab])
    if tabs.any?
      unless tabs.detect {|tab| tab[:name] == selected}
        selected = nil
      end
      selected ||= tabs.first[:name]
      render partial:'common/tabs', locals:{tabs:tabs, selected_tab:selected}
    else
      content_tag 'p', l(:label_no_data), class:"nodata"
    end
  end
end
