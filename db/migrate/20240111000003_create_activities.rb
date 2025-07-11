class CreateActivities < ActiveRecord::Migration[8.0]
  def change
    create_table :activities do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :action, null: false
      t.references :trackable, polymorphic: true, null: false
      t.jsonb :metadata, default: {}
      t.datetime :created_at, null: false
    end

    add_index :activities, [:tenant_id, :created_at]
    add_index :activities, [:trackable_type, :trackable_id]
    add_index :activities, :action
  end
end