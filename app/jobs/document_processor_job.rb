class DocumentProcessorJob < ApplicationJob
  queue_as do
    document = arguments.first
    case document.priority.to_sym
    when :critical, :urgent
      :urgent
    when :high
      :high_priority
    else
      :document_processing
    end
  end

  def perform(document)
    Current.set(tenant: document.tenant) do
      document.process!
      
      # Skip if no extraction template
      unless document.extraction_template
        document.complete!
        return
      end
      
      # Check if document has a file
      unless document.has_file?
        document.fail!("No file attached to document")
        return
      end
      
      # Extract data using AI service
      provider = determine_provider(document)
      extracted_data = AiService.extract_document_data(
        document, 
        provider: provider,
        model: determine_model(document, provider)
      )
      
      # Complete the document with extracted data
      document.complete!(extracted_data)
      
      # Check if review is needed based on confidence scores
      check_review_requirements(document)
      
    rescue StandardError => e
      Rails.logger.error "Document processing failed for document #{document.id}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      document.fail!(e.message)
    end
  end
  
  private
  
  def determine_provider(document)
    # Use model assignment from priority system
    if document.assigned_model.present?
      case document.assigned_model.to_sym
      when :gpt4_vision, :gpt4_turbo
        return :openai
      when :claude_vision
        return :anthropic
      when :fallback
        return :google
      end
    end
    
    # Check document template settings first
    template_provider = document.extraction_template.settings&.dig('ai_provider')
    return template_provider.to_sym if template_provider.present?
    
    # Check tenant settings
    tenant_provider = document.tenant.settings&.dig('default_ai_provider')
    return tenant_provider.to_sym if tenant_provider.present?
    
    # Use system default
    :openai
  end
  
  def determine_model(document, provider)
    # Use model assignment from priority system
    if document.assigned_model.present?
      case document.assigned_model.to_sym
      when :gpt4_vision
        return 'gpt-4-turbo-vision'
      when :gpt4_turbo
        return 'gpt-4-turbo'
      when :claude_vision
        return 'claude-3-opus-20240229'
      when :fallback
        return 'gemini-1.5-flash'
      end
    end
    
    # Check document template settings for model
    template_model = document.extraction_template.settings&.dig('ai_model')
    return template_model if template_model.present?
    
    # Use provider-specific defaults for document extraction
    case provider
    when :openai
      'gpt-4o-mini' # Good balance of cost and performance
    when :anthropic
      'claude-3-haiku-20240307' # Fast and cost-effective
    when :google
      'gemini-1.5-flash' # Fast model for documents
    when :deepseek
      'deepseek-chat'
    end
  end
  
  def check_review_requirements(document)
    # Get confidence threshold from template or use default
    threshold = document.extraction_template.settings&.dig('confidence_threshold') || 0.7
    
    # Check if any required fields have low confidence
    low_confidence_fields = document.extraction_results.joins(:extraction_template).where(
      "extraction_results.confidence_score < ? AND extraction_templates.fields @> ?",
      threshold,
      [{ name: document.extraction_results.pluck(:field_name), required: true }].to_json
    )
    
    if low_confidence_fields.exists?
      document.mark_for_review!("Low confidence scores detected in required fields")
    end
    
    # Auto-approve if configured
    auto_approve = document.extraction_template.settings&.dig('auto_approve')
    if auto_approve && document.completed? && !document.requires_review?
      document.approve!
    end
  end
end