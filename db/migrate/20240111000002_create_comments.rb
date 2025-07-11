class CreateComments < ActiveRecord::Migration[8.0]
  def change
    create_table :comments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :commentable, polymorphic: true, null: false
      t.text :content, null: false
      t.datetime :edited_at

      t.timestamps
    end

    add_index :comments, [:commentable_type, :commentable_id, :created_at], 
              name: "index_comments_on_commentable_and_created_at"
  end
end