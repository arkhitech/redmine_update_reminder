class CreateIntouchSubscriptions < Rails.version < '5.0' ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]
  def change
    create_table :intouch_subscriptions do |t|
      t.belongs_to :user, index: true, foreign_key: true
      t.belongs_to :project, index: true, foreign_key: true
    end
  end
end