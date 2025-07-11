module Api
  module V1
    class DocumentExtractionsController < BaseController
      before_action :set_document, only: [:show, :status]
      
      # POST /api/v1/document_extractions
      def create
        @document = Current.tenant.documents.build(document_params)
        @document.user = current_api_user
        
        if @document.save
          # Queue extraction job
          DocumentProcessorJob.perform_later(@document)
          
          render json: {
            id: @document.id,
            status: 'processing',
            message: 'Document uploaded successfully. Extraction in progress.',
            polling_url: api_v1_document_extraction_status_url(@document)
          }, status: :created
        else
          render json: { errors: @document.errors.full_messages },
                 status: :unprocessable_entity
        end
      end
      
      # GET /api/v1/document_extractions/:id
      def show
        if @document.processed?
          render json: {
            id: @document.id,
            status: @document.status,
            name: @document.name,
            document_type: @document.document_type,
            extracted_data: @document.extracted_data,
            metadata: {
              extracted_at: @document.processed_at,
              confidence_scores: @document.confidence_scores,
              processing_time: processing_time(@document)
            }
          }
        else
          render json: {
            id: @document.id,
            status: @document.status,
            message: status_message(@document),
            polling_url: api_v1_document_extraction_status_url(@document)
          }
        end
      end
      
      # GET /api/v1/document_extractions/:id/status
      def status
        render json: {
          id: @document.id,
          status: @document.status,
          progress: @document.processing_progress || 0,
          message: status_message(@document)
        }
      end
      
      # POST /api/v1/document_extractions/batch
      def batch_create
        documents = []
        errors = []
        
        params[:documents].each_with_index do |doc_params, index|
          document = Current.tenant.documents.build(
            file: doc_params[:file],
            name: doc_params[:name] || doc_params[:file].original_filename,
            extraction_template_id: doc_params[:template_id]
          )
          document.user = current_api_user
          
          if document.save
            DocumentProcessorJob.perform_later(document)
            documents << document
          else
            errors << { index: index, errors: document.errors.full_messages }
          end
        end
        
        render json: {
          created: documents.map { |d| { id: d.id, name: d.name } },
          errors: errors,
          batch_count: documents.count
        }, status: :created
      end
      
      private
      
      def set_document
        @document = Current.tenant.documents.find(params[:id])
      end
      
      def document_params
        params.require(:document).permit(:file, :name, :extraction_template_id, :metadata)
      end
      
      def status_message(document)
        case document.status
        when 'pending'
          'Document is queued for processing'
        when 'processing'
          'Extraction in progress'
        when 'processed'
          'Extraction completed successfully'
        when 'failed'
          'Extraction failed. Please try again.'
        when 'requires_review'
          'Extraction completed but requires manual review'
        else
          'Unknown status'
        end
      end
      
      def processing_time(document)
        return nil unless document.processed_at && document.created_at
        (document.processed_at - document.created_at).round(2)
      end
    end
  end
end