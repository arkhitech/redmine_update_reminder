class CreateIntouchSettings < ActiveRecord::Migration
  def change
    create_table :intouch_settings do |t|

      t.string :name

      t.text :value

      t.integer :project_id

      t.datetime :updated_on


    end

    add_index :intouch_settings, :project_id

  end
end
