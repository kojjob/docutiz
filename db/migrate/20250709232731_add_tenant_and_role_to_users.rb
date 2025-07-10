class AddTenantAndRoleToUsers < ActiveRecord::Migration[8.0]
  def change
    add_reference :users, :tenant, null: false, foreign_key: true
    add_column :users, :name, :string
    add_column :users, :role, :integer
  end
end
