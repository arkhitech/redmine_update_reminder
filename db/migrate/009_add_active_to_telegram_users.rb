class AddActiveToTelegramUsers < Rails.version < '5.0' ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]
  def up
    add_column :telegram_users, :active, :boolean, default: true, null: false
  end

  def down
    remove_column :telegram_users, :active
  end
end
