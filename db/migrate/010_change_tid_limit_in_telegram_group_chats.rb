class ChangeTidLimitInTelegramGroupChats < ActiveRecord::Migration
  def up
    change_column :telegram_group_chats, :tid, :integer, limit: 8
  end

  def down
    change_column :telegram_group_chats, :tid, :integer, limit: 4
  end
end
