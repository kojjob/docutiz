class CreateExtractionTemplates < ActiveRecord::Migration[8.0]
  def change
    create_table :extraction_templates do |t|
      t.references :tenant, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.string :document_type, null: false
      t.jsonb :fields, null: false, default: []
      t.text :prompt_template, null: false
      t.jsonb :settings, null: false, default: {}
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :extraction_templates, [ :tenant_id, :name ], unique: true
    add_index :extraction_templates, :document_type
    add_index :extraction_templates, :active
  end
end
