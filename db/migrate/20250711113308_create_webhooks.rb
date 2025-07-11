class CreateWebhooks < ActiveRecord::Migration[8.0]
  def change
    create_table :webhooks do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :url, null: false
      t.string :secret_key
      t.string :events, array: true, default: []
      t.boolean :active, default: true, null: false
      t.jsonb :headers, default: {}
      t.integer :retry_count, default: 3
      t.integer :timeout_seconds, default: 30
      t.datetime :last_triggered_at
      t.integer :total_deliveries, default: 0
      t.integer :successful_deliveries, default: 0
      t.integer :failed_deliveries, default: 0

      t.timestamps
    end

    add_index :webhooks, :active
    add_index :webhooks, :events, using: :gin
  end
end
