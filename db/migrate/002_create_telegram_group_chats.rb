class CreateTelegramGroupChats < ActiveRecord::Migration
  def change
    create_table :telegram_group_chats do |t|
      t.integer :tid, index: true
      t.string :title
    end
  end
end
