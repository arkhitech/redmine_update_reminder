class AddIntouchDataToIssues < Rails.version < '5.0' ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]
  def up
    add_column :issues, :intouch_data, :text
  end

  def down
    remove_column :issues, :intouch_data
  end
end
