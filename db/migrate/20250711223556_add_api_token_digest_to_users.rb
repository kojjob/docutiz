class AddApiTokenDigestToUsers < ActiveRecord::Migration[8.0]
  def up
    add_column :users, :api_token_digest, :string
    add_index :users, :api_token_digest
    
    # Migrate existing tokens to hashed versions
    User.reset_column_information
    User.find_each do |user|
      if user.api_token.present?
        user.update_column(:api_token_digest, Digest::SHA256.hexdigest(user.api_token))
      end
    end
    
    # Remove the plain text api_token column after migration
    remove_column :users, :api_token
  end
  
  def down
    add_column :users, :api_token, :string
    add_index :users, :api_token, unique: true
    
    # Note: We cannot reverse the hashing, so tokens will need to be regenerated
    remove_index :users, :api_token_digest
    remove_column :users, :api_token_digest
  end
end
