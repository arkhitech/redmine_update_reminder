class CreateSettingsTemplates < ActiveRecord::Migration
  def change
    create_table :settings_templates do |t|
      t.string :name
      t.text :settings
    end
  end
end
