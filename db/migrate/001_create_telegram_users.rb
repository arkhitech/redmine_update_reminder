class CreateTelegramUsers < ActiveRecord::Migration
  def change
    create_table :telegram_users do |t|
      t.integer :tid, index: true
      t.string :username
      t.string :first_name
      t.string :last_name
      t.belongs_to :user, index: true, foreign_key: true
    end
  end
end
