class RemoveIntouchSettings < ActiveRecord::Migration
  def up
    remove_index :intouch_settings, :project_id
    drop_table :intouch_settings
  end

  def down
    create_table :intouch_settings do |t|

      t.string :name

      t.text :value

      t.integer :project_id

      t.datetime :updated_on


    end

    add_index :intouch_settings, :project_id

  end
end
