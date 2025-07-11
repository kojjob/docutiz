class AddApiTokenToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :api_token, :string
    add_index :users, :api_token, unique: true
    add_column :users, :api_token_last_used_at, :datetime
    add_column :users, :api_requests_count, :integer, default: 0
  end
end
