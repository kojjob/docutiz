module Prioritizable
  extend ActiveSupport::Concern
  
  PRIORITY_LEVELS = {
    low: 0,
    normal: 1,
    high: 2,
    urgent: 3,
    critical: 4
  }.freeze
  
  PRIORITY_REASONS = {
    manual: "Manually prioritized",
    subscription: "Premium subscription",
    retry_failure: "Previous processing failure",
    document_type: "High-priority document type",
    deadline: "Approaching deadline",
    bulk_operation: "Part of bulk operation",
    api_request: "API request with priority"
  }.freeze
  
  AI_MODELS = {
    gpt4_vision: "GPT-4 Vision",
    claude_vision: "Claude Vision",
    gpt4_turbo: "GPT-4 Turbo",
    fallback: "Fallback Model"
  }.freeze
  
  included do
    enum :priority, PRIORITY_LEVELS, prefix: true
    
    scope :queue_order, -> { order(priority: :desc, created_at: :asc) }
    scope :pending_processing, -> { where(status: ['pending', 'processing']) }
    scope :ready_for_processing, -> { pending_processing.where(processing_started_at: nil) }
    scope :stale_processing, -> { where(status: 'processing').where('processing_started_at < ?', 30.minutes.ago) }
    
    before_save :set_estimated_completion_time, if: :processing_started_at_changed?
  end
  
  def set_priority!(level, reason = nil)
    self.priority = level
    self.priority_reason = reason || PRIORITY_REASONS[:manual]
    save!
  end
  
  def escalate_priority!
    return if priority_critical?
    
    next_level = PRIORITY_LEVELS.key(PRIORITY_LEVELS[priority] + 1)
    set_priority!(next_level, PRIORITY_REASONS[:retry_failure])
  end
  
  def processing_time_estimate
    base_time = case file_size
                when 0..1.megabyte then 30.seconds
                when 1..5.megabytes then 1.minute
                when 5..10.megabytes then 2.minutes
                else 5.minutes
                end
    
    # Adjust based on template complexity
    if extraction_template&.schema.present?
      field_count = extraction_template.schema.dig("fields")&.count || 0
      base_time += (field_count * 5.seconds)
    end
    
    base_time
  end
  
  def set_estimated_completion_time
    return unless processing_started_at.present?
    
    self.estimated_completion_at = processing_started_at + processing_time_estimate
  end
  
  def overdue?
    return false unless estimated_completion_at.present?
    
    Time.current > estimated_completion_at && status == 'processing'
  end
  
  def select_ai_model
    # Start with default model based on priority
    model = case priority.to_sym
            when :critical, :urgent
              :gpt4_vision
            when :high
              retry_count > 0 ? :claude_vision : :gpt4_vision
            else
              :claude_vision
            end
    
    # Switch models on retry
    if retry_count > 0
      models = AI_MODELS.keys - [:fallback]
      current_index = models.index(assigned_model&.to_sym) || 0
      model = models[(current_index + 1) % models.length]
    end
    
    # Use fallback after multiple failures
    model = :fallback if retry_count > 2
    
    self.assigned_model = model.to_s
    model
  end
end