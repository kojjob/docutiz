class DocumentQueueService
  def self.next_document(tenant)
    new(tenant).next_document
  end
  
  def self.queue_stats(tenant)
    new(tenant).queue_stats
  end
  
  def self.requeue_stale_documents
    new.requeue_stale_documents
  end
  
  def initialize(tenant = nil)
    @tenant = tenant
  end
  
  def next_document
    return unless @tenant
    
    Current.set(tenant: @tenant) do
      # Find the next document to process based on priority
      @tenant.documents
             .ready_for_processing
             .queue_order
             .first
    end
  end
  
  def queue_stats
    return {} unless @tenant
    
    Current.set(tenant: @tenant) do
      {
        total_pending: @tenant.documents.pending_processing.count,
        by_priority: count_by_priority,
        by_status: count_by_status,
        average_wait_time: calculate_average_wait_time,
        processing_rate: calculate_processing_rate,
        estimated_completion: estimate_queue_completion
      }
    end
  end
  
  def requeue_stale_documents
    # Find documents that have been processing for too long
    stale_documents = Document.stale_processing
    
    stale_documents.find_each do |document|
      Current.set(tenant: document.tenant) do
        Rails.logger.warn "Document #{document.id} has been processing for over 30 minutes, requeueing"
        
        # Reset the document to pending with increased priority
        document.update!(
          status: 'pending',
          processing_started_at: nil,
          last_error: "Processing timeout - automatically requeued"
        )
        
        # Escalate priority for stale documents
        document.escalate_priority!
        
        # Re-enqueue the job
        DocumentProcessorJob.perform_later(document)
      end
    end
    
    stale_documents.count
  end
  
  def estimate_processing_time(document)
    # Get historical processing times for similar documents
    similar_documents = Document
      .where(tenant: document.tenant)
      .where(extraction_template: document.extraction_template)
      .where.not(processing_completed_at: nil)
      .where.not(processing_started_at: nil)
      .limit(10)
    
    if similar_documents.any?
      # Calculate average processing time
      total_time = similar_documents.sum { |d| d.processing_completed_at - d.processing_started_at }
      average_time = total_time / similar_documents.count
      
      # Adjust based on file size
      size_factor = document.file_size.to_f / (similar_documents.average(:file_size) || document.file_size)
      average_time * size_factor
    else
      # Use default estimate
      document.processing_time_estimate
    end
  end
  
  private
  
  def count_by_priority
    @tenant.documents
           .pending_processing
           .group(:priority)
           .count
           .transform_keys { |k| Document.priorities.key(k) }
  end
  
  def count_by_status
    @tenant.documents
           .group(:status)
           .count
  end
  
  def calculate_average_wait_time
    pending_docs = @tenant.documents.pending
    
    return 0 if pending_docs.empty?
    
    total_wait = pending_docs.sum { |doc| Time.current - doc.created_at }
    total_wait / pending_docs.count
  end
  
  def calculate_processing_rate
    # Documents processed in the last hour
    processed_last_hour = @tenant.documents
      .where(status: ['completed', 'approved'])
      .where('processing_completed_at > ?', 1.hour.ago)
      .count
    
    # Return rate per minute
    processed_last_hour / 60.0
  end
  
  def estimate_queue_completion
    pending_count = @tenant.documents.pending_processing.count
    processing_rate = calculate_processing_rate
    
    return nil if processing_rate == 0
    
    # Estimate minutes to process all pending documents
    minutes_to_complete = pending_count / processing_rate
    Time.current + minutes_to_complete.minutes
  end
end