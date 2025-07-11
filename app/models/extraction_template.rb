class ExtractionTemplate < ApplicationRecord
  # Associations
  belongs_to :tenant
  has_many :documents, dependent: :nullify
  has_many :extraction_results, through: :documents

  # Validations
  validates :name, presence: true, uniqueness: { scope: :tenant_id }
  validates :document_type, presence: true
  validates :fields, presence: true
  validates :prompt_template, presence: true

  # Scopes
  scope :active, -> { where(active: true) }
  scope :by_document_type, ->(type) { where(document_type: type) }

  # Callbacks
  after_create_commit :trigger_created_webhook
  after_update_commit :trigger_updated_webhook

  # Document types
  DOCUMENT_TYPES = %w[
    invoice
    receipt
    bank_statement
    contract
    form
    id_document
    other
  ].freeze

  validates :document_type, inclusion: { in: DOCUMENT_TYPES }

  # Default settings
  after_initialize do
    self.settings ||= {
      "confidence_threshold" => 0.8,
      "require_human_review" => false,
      "auto_approve" => true
    }
    self.fields ||= []
    self.active = true if active.nil?
  end

  # Instance methods
  def field_names
    fields.map { |f| f["name"] }
  end

  def required_fields
    fields.select { |f| f["required"] == true }
  end

  def optional_fields
    fields.reject { |f| f["required"] == true }
  end

  def generate_prompt(document_context = {})
    # Replace template variables with actual values
    prompt = prompt_template.dup
    
    document_context.each do |key, value|
      prompt.gsub!("{{#{key}}}", value.to_s)
    end
    
    # Replace fields_list with formatted field descriptions
    if prompt.include?("{{fields_list}}")
      fields_description = fields.map do |field|
        "- #{field['name']}: #{field['description']}"
      end.join("\n")
      prompt.gsub!("{{fields_list}}", fields_description)
    end
    
    prompt
  end
  
  def average_confidence_score
    return 0.0 if extraction_results.empty?
    
    extraction_results.average(:confidence_score) || 0.0
  end
  
  def extraction_success_rate
    return 0.0 if extraction_results.empty?
    
    successful = extraction_results.where('confidence_score >= ?', 0.8).count
    total = extraction_results.count
    
    (successful.to_f / total * 100).round(1)
  end

  private

  def trigger_created_webhook
    trigger_webhook("template.created")
  end

  def trigger_updated_webhook
    trigger_webhook("template.updated")
  end

  def trigger_webhook(event)
    payload = {
      event: event,
      timestamp: Time.current.iso8601,
      template: {
        id: id,
        name: name,
        document_type: document_type,
        active: active,
        fields_count: fields.size,
        settings: settings,
        created_at: created_at.iso8601,
        updated_at: updated_at.iso8601
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
