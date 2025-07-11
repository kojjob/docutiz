# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_07_11_223556) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "activities", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.bigint "user_id", null: false
    t.string "action", null: false
    t.string "trackable_type", null: false
    t.bigint "trackable_id", null: false
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.index ["action"], name: "index_activities_on_action"
    t.index ["tenant_id", "created_at"], name: "index_activities_on_tenant_id_and_created_at"
    t.index ["tenant_id"], name: "index_activities_on_tenant_id"
    t.index ["trackable_type", "trackable_id"], name: "index_activities_on_trackable"
    t.index ["trackable_type", "trackable_id"], name: "index_activities_on_trackable_type_and_trackable_id"
    t.index ["user_id"], name: "index_activities_on_user_id"
  end

  create_table "comments", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "commentable_type", null: false
    t.bigint "commentable_id", null: false
    t.text "content", null: false
    t.datetime "edited_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["commentable_type", "commentable_id", "created_at"], name: "index_comments_on_commentable_and_created_at"
    t.index ["commentable_type", "commentable_id"], name: "index_comments_on_commentable"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "documents", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.bigint "user_id", null: false
    t.bigint "extraction_template_id"
    t.string "name", null: false
    t.text "description"
    t.string "status", default: "pending", null: false
    t.string "original_filename"
    t.string "content_type"
    t.bigint "file_size"
    t.jsonb "extracted_data", default: {}, null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "processing_started_at"
    t.datetime "processing_completed_at"
    t.text "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "estimated_completion_at"
    t.integer "retry_count", default: 0, null: false
    t.text "last_error"
    t.string "priority_reason"
    t.string "assigned_model"
    t.index ["extraction_template_id"], name: "index_documents_on_extraction_template_id"
    t.index ["priority"], name: "index_documents_on_priority"
    t.index ["processing_started_at"], name: "index_documents_on_processing_started_at"
    t.index ["status", "priority", "created_at"], name: "index_documents_on_queue_priority"
    t.index ["status"], name: "index_documents_on_status"
    t.index ["tenant_id", "status"], name: "index_documents_on_tenant_id_and_status"
    t.index ["tenant_id"], name: "index_documents_on_tenant_id"
    t.index ["user_id", "created_at"], name: "index_documents_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_documents_on_user_id"
  end

  create_table "extraction_results", force: :cascade do |t|
    t.bigint "document_id", null: false
    t.string "field_name", null: false
    t.text "field_value"
    t.float "confidence_score"
    t.string "ai_model"
    t.jsonb "raw_response", default: {}, null: false
    t.bigint "created_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ai_model"], name: "index_extraction_results_on_ai_model"
    t.index ["confidence_score"], name: "index_extraction_results_on_confidence_score"
    t.index ["created_by_id"], name: "index_extraction_results_on_created_by_id"
    t.index ["document_id", "field_name"], name: "index_extraction_results_on_document_id_and_field_name"
    t.index ["document_id"], name: "index_extraction_results_on_document_id"
  end

  create_table "extraction_templates", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.string "name", null: false
    t.text "description"
    t.string "document_type", null: false
    t.jsonb "fields", default: [], null: false
    t.text "prompt_template", null: false
    t.jsonb "settings", default: {}, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_extraction_templates_on_active"
    t.index ["document_type"], name: "index_extraction_templates_on_document_type"
    t.index ["tenant_id", "name"], name: "index_extraction_templates_on_tenant_id_and_name", unique: true
    t.index ["tenant_id"], name: "index_extraction_templates_on_tenant_id"
  end

  create_table "team_invitations", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.bigint "invited_by_id", null: false
    t.string "email", null: false
    t.string "name"
    t.string "role", default: "member"
    t.string "token", null: false
    t.datetime "accepted_at"
    t.datetime "expires_at", null: false
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_team_invitations_on_expires_at"
    t.index ["invited_by_id"], name: "index_team_invitations_on_invited_by_id"
    t.index ["tenant_id", "email"], name: "index_team_invitations_on_tenant_id_and_email", where: "(accepted_at IS NULL)"
    t.index ["tenant_id"], name: "index_team_invitations_on_tenant_id"
    t.index ["token"], name: "index_team_invitations_on_token", unique: true
    t.index ["user_id"], name: "index_team_invitations_on_user_id"
  end

  create_table "tenants", force: :cascade do |t|
    t.string "name"
    t.string "subdomain"
    t.jsonb "settings", default: {}
    t.string "plan", default: "trial"
    t.datetime "trial_ends_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["subdomain"], name: "index_tenants_on_subdomain", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "tenant_id", null: false
    t.string "name"
    t.integer "role"
    t.datetime "api_token_last_used_at"
    t.integer "api_requests_count", default: 0
    t.jsonb "settings", default: {}
    t.string "api_token_digest"
    t.index ["api_token_digest"], name: "index_users_on_api_token_digest"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["settings"], name: "index_users_on_settings", using: :gin
    t.index ["tenant_id"], name: "index_users_on_tenant_id"
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  create_table "webhook_events", force: :cascade do |t|
    t.bigint "webhook_id", null: false
    t.string "event_type", null: false
    t.string "status", default: "pending", null: false
    t.jsonb "payload", default: {}
    t.jsonb "response_headers"
    t.text "response_body"
    t.integer "response_code"
    t.float "response_time"
    t.integer "attempt_count", default: 0
    t.datetime "delivered_at"
    t.datetime "next_retry_at"
    t.text "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_webhook_events_on_created_at"
    t.index ["event_type"], name: "index_webhook_events_on_event_type"
    t.index ["status"], name: "index_webhook_events_on_status"
    t.index ["webhook_id", "status"], name: "index_webhook_events_on_webhook_id_and_status"
    t.index ["webhook_id"], name: "index_webhook_events_on_webhook_id"
  end

  create_table "webhooks", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.string "url", null: false
    t.string "secret_key"
    t.string "events", default: [], array: true
    t.boolean "active", default: true, null: false
    t.jsonb "headers", default: {}
    t.integer "retry_count", default: 3
    t.integer "timeout_seconds", default: 30
    t.datetime "last_triggered_at"
    t.integer "total_deliveries", default: 0
    t.integer "successful_deliveries", default: 0
    t.integer "failed_deliveries", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_webhooks_on_active"
    t.index ["events"], name: "index_webhooks_on_events", using: :gin
    t.index ["tenant_id"], name: "index_webhooks_on_tenant_id"
    t.index ["user_id"], name: "index_webhooks_on_user_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "activities", "tenants"
  add_foreign_key "activities", "users"
  add_foreign_key "comments", "users"
  add_foreign_key "documents", "extraction_templates"
  add_foreign_key "documents", "tenants"
  add_foreign_key "documents", "users"
  add_foreign_key "extraction_results", "documents"
  add_foreign_key "extraction_results", "users", column: "created_by_id"
  add_foreign_key "extraction_templates", "tenants"
  add_foreign_key "team_invitations", "tenants"
  add_foreign_key "team_invitations", "users"
  add_foreign_key "team_invitations", "users", column: "invited_by_id"
  add_foreign_key "users", "tenants"
  add_foreign_key "webhook_events", "webhooks"
  add_foreign_key "webhooks", "tenants"
  add_foreign_key "webhooks", "users"
end
