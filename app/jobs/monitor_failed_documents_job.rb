class MonitorFailedDocumentsJob < ApplicationJob
  queue_as :low
  
  def perform
    # Find documents that failed recently and haven't exceeded retry limit
    failed_documents = Document
      .failed
      .where('updated_at > ?', 1.hour.ago)
      .where('retry_count < ?', 3)
      .includes(:tenant)
    
    failed_documents.find_each do |document|
      Current.set(tenant: document.tenant) do
        # Schedule retry based on retry count
        delay = case document.retry_count
                when 0 then 5.minutes
                when 1 then 15.minutes
                when 2 then 30.minutes
                else 1.hour
                end
        
        # Check if enough time has passed since last attempt
        time_since_failure = Time.current - document.updated_at
        
        if time_since_failure >= delay
          DocumentRetryJob.perform_later(document)
          Rails.logger.info "Scheduled retry for document #{document.id} after #{delay}"
        end
      end
    end
    
    Rails.logger.info "Monitored #{failed_documents.count} failed documents for retry"
  end
end