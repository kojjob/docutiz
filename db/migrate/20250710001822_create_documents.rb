class CreateDocuments < ActiveRecord::Migration[8.0]
  def change
    create_table :documents do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :extraction_template, null: true, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.string :status, null: false, default: 'pending'
      t.string :original_filename
      t.string :content_type
      t.bigint :file_size
      t.jsonb :extracted_data, null: false, default: {}
      t.jsonb :metadata, null: false, default: {}
      t.datetime :processing_started_at
      t.datetime :processing_completed_at
      t.text :error_message

      t.timestamps
    end

    add_index :documents, :status
    add_index :documents, [ :tenant_id, :status ]
    add_index :documents, [ :user_id, :created_at ]
    add_index :documents, :processing_started_at
  end
end
