class Document < ApplicationRecord
  include Prioritizable
  
  # Associations
  belongs_to :tenant
  belongs_to :user
  belongs_to :extraction_template, optional: true
  has_many :extraction_results, dependent: :destroy
  has_one_attached :file
  has_many :comments, as: :commentable, dependent: :destroy
  has_many :activities, as: :trackable, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :status, presence: true

  # Status management
  STATUSES = %w[
    pending
    processing
    completed
    failed
    requires_review
    approved
  ].freeze

  validates :status, inclusion: { in: STATUSES }

  # Scopes
  scope :pending, -> { where(status: "pending") }
  scope :processing, -> { where(status: "processing") }
  scope :completed, -> { where(status: [ "completed", "approved" ]) }
  scope :failed, -> { where(status: "failed") }
  scope :requires_review, -> { where(status: "requires_review") }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_template, ->(template) { where(extraction_template: template) }

  # Callbacks
  before_validation :set_defaults, on: :create
  before_create :detect_document_priority
  after_create_commit :enqueue_processing_job
  after_create_commit :trigger_created_webhook
  after_update_commit :trigger_status_webhooks

  # Instance methods
  def pending?
    status == "pending"
  end

  def processing?
    status == "processing"
  end

  def completed?
    status == "completed"
  end

  def failed?
    status == "failed"
  end

  def requires_review?
    status == "requires_review"
  end

  def approved?
    status == "approved"
  end

  def process!
    select_ai_model
    update!(
      status: "processing",
      processing_started_at: Time.current,
      error_message: nil,
      last_error: nil
    )
  end

  def complete!(extracted_data = {})
    update!(
      status: "completed",
      processing_completed_at: Time.current,
      extracted_data: extracted_data
    )
  end

  def fail!(error_message)
    update!(
      status: "failed",
      processing_completed_at: Time.current,
      error_message: error_message,
      last_error: error_message,
      retry_count: retry_count + 1
    )
    
    # Escalate priority on failure
    escalate_priority! if retry_count < 3
  end

  def mark_for_review!(reason = nil)
    update!(
      status: "requires_review",
      metadata: metadata.merge("review_reason" => reason)
    )
  end

  def approve!
    update!(status: "approved") if requires_review?
  end

  def processing_time
    return nil unless processing_started_at && processing_completed_at
    processing_completed_at - processing_started_at
  end

  def has_file?
    file.attached?
  end

  def file_url
    return nil unless has_file?
    
    # For AI services, we need a full URL
    if Rails.application.config.active_storage.variant_processor
      Rails.application.routes.url_helpers.rails_blob_url(file, host: default_url_host)
    else
      Rails.application.routes.url_helpers.rails_blob_url(file, only_path: true)
    end
  end
  
  def default_url_host
    # In production, this should come from config
    Rails.application.config.action_mailer.default_url_options&.dig(:host) || 
      "http://localhost:3000"
  end

  private

  def set_defaults
    self.status ||= "pending"
    self.metadata ||= {}
    self.extracted_data ||= {}
    self.name ||= original_filename if original_filename.present?
    self.priority ||= :normal
    self.retry_count ||= 0
  end
  
  def detect_document_priority
    # Check user subscription level
    if user.subscription&.plan == "premium"
      self.priority = :high
      self.priority_reason = "Premium subscription"
      return
    end
    
    # Check document type from filename/content type
    if original_filename.present?
      case original_filename.downcase
      when /invoice|receipt|bill/
        self.priority = :high
        self.priority_reason = "High-priority document type"
      when /contract|agreement|legal/
        self.priority = :urgent
        self.priority_reason = "Critical document type"
      end
    end
    
    # Check if part of bulk upload
    if metadata&.dig("bulk_upload")
      self.priority = :low
      self.priority_reason = "Bulk operation"
    end
  end

  def enqueue_processing_job
    # Only enqueue if there's an extraction template
    return unless extraction_template.present?
    
    DocumentProcessorJob.perform_later(self)
  end

  def trigger_created_webhook
    trigger_webhook("document.created")
  end

  def trigger_status_webhooks
    # Only trigger if status actually changed
    return unless saved_change_to_status?

    case status
    when "completed"
      trigger_webhook("document.processed")
      trigger_webhook("extraction.completed")
    when "approved"
      trigger_webhook("document.approved")
    when "requires_review"
      trigger_webhook("document.rejected")
    when "failed"
      trigger_webhook("extraction.failed")
    end
  end

  def trigger_webhook(event)
    payload = {
      event: event,
      timestamp: Time.current.iso8601,
      document: {
        id: id,
        name: name,
        status: status,
        original_filename: original_filename,
        content_type: content_type,
        file_size: file_size,
        extraction_template_id: extraction_template_id,
        extraction_template_name: extraction_template&.name,
        created_at: created_at.iso8601,
        updated_at: updated_at.iso8601,
        processing_started_at: processing_started_at&.iso8601,
        processing_completed_at: processing_completed_at&.iso8601,
        extracted_data: extracted_data,
        metadata: metadata
      },
      user: {
        id: user.id,
        name: user.name,
        email: user.email
      },
      tenant: {
        id: tenant.id,
        name: tenant.name,
        subdomain: tenant.subdomain
      }
    }

    # Find all active webhooks for this event
    tenant.webhooks.for_event(event).each do |webhook|
      webhook.trigger(event, payload)
    end
  end
end
