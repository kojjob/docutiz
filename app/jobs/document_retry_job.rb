class DocumentRetryJob < ApplicationJob
  queue_as :high_priority
  
  # Retry job itself up to 3 times with exponential backoff
  retry_on StandardError, wait: :exponentially_longer, attempts: 3
  
  def perform(document)
    Current.set(tenant: document.tenant) do
      # Check if document is still in failed state
      return unless document.failed?
      
      # Check retry limit
      if document.retry_count >= 3
        Rails.logger.info "Document #{document.id} has reached maximum retry attempts"
        return
      end
      
      # Reset status to pending for reprocessing
      document.update!(status: 'pending')
      
      # Enqueue with higher priority
      DocumentProcessorJob.set(priority: 10).perform_later(document)
      
      Rails.logger.info "Document #{document.id} queued for retry attempt #{document.retry_count + 1}"
    end
  end
end