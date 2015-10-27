class AddActiveToTelegramUsers < ActiveRecord::Migration
  def up
    add_column :telegram_users, :active, :boolean, default: true, null: false
  end

  def down
    remove_column :telegram_users, :active
  end
end
