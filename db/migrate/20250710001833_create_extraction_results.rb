class CreateExtractionResults < ActiveRecord::Migration[8.0]
  def change
    create_table :extraction_results do |t|
      t.references :document, null: false, foreign_key: true
      t.string :field_name, null: false
      t.text :field_value
      t.float :confidence_score
      t.string :ai_model
      t.jsonb :raw_response, null: false, default: {}
      t.references :created_by, null: true, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :extraction_results, [ :document_id, :field_name ]
    add_index :extraction_results, :confidence_score
    add_index :extraction_results, :ai_model
  end
end
