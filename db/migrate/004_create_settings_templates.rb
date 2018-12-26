class CreateSettingsTemplates < Rails.version < '5.0' ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]
  def change
    create_table :settings_templates do |t|
      t.string :name
      t.text :settings
    end
  end
end
