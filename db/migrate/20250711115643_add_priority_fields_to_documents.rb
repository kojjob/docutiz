class AddPriorityFieldsToDocuments < ActiveRecord::Migration[8.0]
  def change
    add_column :documents, :priority, :integer, default: 0, null: false unless column_exists?(:documents, :priority)
    add_column :documents, :estimated_completion_at, :datetime unless column_exists?(:documents, :estimated_completion_at)
    add_column :documents, :retry_count, :integer, default: 0, null: false unless column_exists?(:documents, :retry_count)
    add_column :documents, :last_error, :text unless column_exists?(:documents, :last_error)
    add_column :documents, :priority_reason, :string unless column_exists?(:documents, :priority_reason)
    add_column :documents, :assigned_model, :string unless column_exists?(:documents, :assigned_model)
    
    add_index :documents, :priority unless index_exists?(:documents, :priority)
    add_index :documents, [:status, :priority, :created_at], name: 'index_documents_on_queue_priority' unless index_exists?(:documents, [:status, :priority, :created_at], name: 'index_documents_on_queue_priority')
  end
end