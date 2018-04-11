class CreateIntouchSubscriptions < ActiveRecord::Migration
  def change
    create_table :intouch_subscriptions do |t|
      t.belongs_to :user, index: true, foreign_key: true
      t.belongs_to :project, index: true, foreign_key: true
    end
  end
end