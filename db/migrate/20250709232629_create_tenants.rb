class CreateTenants < ActiveRecord::Migration[8.0]
  def change
    create_table :tenants do |t|
      t.string :name
      t.string :subdomain
      t.jsonb :settings
      t.string :plan
      t.datetime :trial_ends_at

      t.timestamps
    end
    add_index :tenants, :subdomain, unique: true
  end
end
