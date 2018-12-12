class CreateTelegramGroupChats < Rails.version < '5.0' ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]
  def change
    create_table :telegram_group_chats do |t|
      t.integer :tid, index: true
      t.string :title
    end
  end
end
