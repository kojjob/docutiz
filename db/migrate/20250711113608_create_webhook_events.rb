class CreateWebhookEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :webhook_events do |t|
      t.references :webhook, null: false, foreign_key: true
      t.string :event_type, null: false
      t.string :status, null: false, default: 'pending'
      t.jsonb :payload, default: {}
      t.jsonb :response_headers
      t.text :response_body
      t.integer :response_code
      t.float :response_time
      t.integer :attempt_count, default: 0
      t.datetime :delivered_at
      t.datetime :next_retry_at
      t.text :error_message

      t.timestamps
    end

    add_index :webhook_events, :status
    add_index :webhook_events, :event_type
    add_index :webhook_events, :created_at
    add_index :webhook_events, [:webhook_id, :status]
  end
end
