class ExtractionResult < ApplicationRecord
  # Associations
  belongs_to :document
  belongs_to :created_by, class_name: "User", optional: true
  has_one :tenant, through: :document
  has_one :extraction_template, through: :document

  # Validations
  validates :field_name, presence: true
  validates :confidence_score, numericality: {
    greater_than_or_equal_to: 0.0,
    less_than_or_equal_to: 1.0
  }, allow_nil: true

  # Scopes
  scope :high_confidence, -> { where("confidence_score >= ?", 0.8) }
  scope :medium_confidence, -> { where("confidence_score >= ? AND confidence_score < ?", 0.5, 0.8) }
  scope :low_confidence, -> { where("confidence_score < ?", 0.5) }
  scope :by_field, ->(field) { where(field_name: field) }
  scope :by_ai_model, ->(model) { where(ai_model: model) }
  scope :recent, -> { order(created_at: :desc) }

  # AI Models
  AI_MODELS = %w[
    gpt-4-vision
    gpt-4-turbo
    claude-3-opus
    claude-3-sonnet
    manual
  ].freeze

  validates :ai_model, inclusion: { in: AI_MODELS }, allow_nil: true

  # Callbacks
  after_initialize :set_defaults

  # Instance methods
  def high_confidence?
    confidence_score && confidence_score >= 0.8
  end

  def medium_confidence?
    confidence_score && confidence_score >= 0.5 && confidence_score < 0.8
  end

  def low_confidence?
    confidence_score && confidence_score < 0.5
  end

  def requires_review?
    low_confidence? || ai_model == "manual"
  end

  def confidence_percentage
    return nil unless confidence_score
    (confidence_score * 100).round(1)
  end

  def field_type
    return nil unless document.extraction_template
    field = document.extraction_template.fields.find { |f| f["name"] == field_name }
    field ? field["type"] : nil
  end

  private

  def set_defaults
    self.raw_response ||= {}
  end
end
