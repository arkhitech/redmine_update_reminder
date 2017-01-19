class AddIntouchDataToIssues < ActiveRecord::Migration
  def up
    add_column :issues, :intouch_data, :text
  end

  def down
    remove_column :issues, :intouch_data
  end
end
