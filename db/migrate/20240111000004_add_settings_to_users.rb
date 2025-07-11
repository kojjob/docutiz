class AddSettingsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :settings, :jsonb, default: {}
    add_index :users, :settings, using: :gin
  end
end