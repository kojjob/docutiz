class DocumentQueuesController < ApplicationController
  layout 'dashboard'
  before_action :require_tenant!
  before_action :require_admin!
  
  def index
    @queue_stats = DocumentQueueService.queue_stats(Current.tenant)
    @pending_documents = Current.tenant.documents
                                      .pending_processing
                                      .includes(:user, :extraction_template)
                                      .queue_order
                                      .limit(20)
    
    @processing_documents = Current.tenant.documents
                                         .processing
                                         .includes(:user, :extraction_template)
                                         .order(processing_started_at: :asc)
    
    @recent_failures = Current.tenant.documents
                                    .failed
                                    .includes(:user, :extraction_template)
                                    .order(updated_at: :desc)
                                    .limit(10)
  end
  
  def requeue
    document = Current.tenant.documents.find(params[:id])
    
    if document.failed?
      document.update!(status: 'pending')
      DocumentProcessorJob.perform_later(document)
      redirect_to document_queues_path, notice: "Document requeued for processing."
    else
      redirect_to document_queues_path, alert: "Only failed documents can be requeued."
    end
  end
  
  def priority
    document = Current.tenant.documents.find(params[:id])
    new_priority = params[:priority]
    
    if Document.priorities.keys.include?(new_priority)
      document.set_priority!(new_priority, "Manual priority adjustment")
      redirect_to document_queues_path, notice: "Document priority updated."
    else
      redirect_to document_queues_path, alert: "Invalid priority level."
    end
  end
  
  def clear_stale
    count = DocumentQueueService.requeue_stale_documents
    redirect_to document_queues_path, notice: "#{count} stale documents requeued."
  end
  
  private
  
  def require_admin!
    unless current_user.can_manage_users?
      redirect_to documents_path, alert: "You don't have permission to access the queue dashboard."
    end
  end
end