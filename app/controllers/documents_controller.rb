class DocumentsController < ApplicationController
  layout 'dashboard'
  include Pagy::Backend
  
  before_action :require_tenant!
  before_action :set_document, only: %i[show edit update destroy approve reject]

  def index
    @pagy, @documents = pagy(Current.tenant.documents
                                           .includes(:user, :extraction_template, file_attachment: :blob)
                                           .order(created_at: :desc))
  end

  def show
    @extraction_results = @document.extraction_results.includes(:created_by)
  end

  def new
    @document = Current.tenant.documents.build
    @extraction_templates = Current.tenant.extraction_templates.order(:name)
  end

  def create
    @document = Current.tenant.documents.build(document_params)
    @document.user = current_user
    
    # Store file metadata
    if params[:document][:file].present?
      file = params[:document][:file]
      @document.original_filename = file.original_filename
      @document.content_type = file.content_type
      @document.file_size = file.size
    end

    if @document.save
      redirect_to @document, notice: "Document uploaded successfully. Processing will begin shortly."
    else
      @extraction_templates = Current.tenant.extraction_templates.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @extraction_templates = Current.tenant.extraction_templates.order(:name)
  end

  def update
    # Handle manual processing in development
    if Rails.env.development? && params[:process] == "true"
      DocumentProcessorJob.perform_now(@document)
      redirect_to @document, notice: "Document processing initiated."
      return
    end
    
    if @document.update(document_params)
      redirect_to @document, notice: "Document updated successfully."
    else
      @extraction_templates = Current.tenant.extraction_templates.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @document.destroy!
    redirect_to documents_path, notice: "Document deleted successfully."
  end

  def approve
    @document.update!(status: "approved")
    redirect_to @document, notice: "Document approved successfully."
  end

  def reject
    @document.update!(status: "requires_review")
    redirect_to @document, notice: "Document sent back for review."
  end

  def bulk_upload
    @extraction_templates = Current.tenant.extraction_templates.active.order(:name)
  end

  def bulk_create
    uploaded_files = params[:files] || []
    template_id = params[:extraction_template_id]
    
    success_count = 0
    error_count = 0
    errors = []

    uploaded_files.each do |file|
      document = Current.tenant.documents.build(
        name: File.basename(file.original_filename, ".*"),
        extraction_template_id: template_id,
        user: current_user,
        original_filename: file.original_filename,
        content_type: file.content_type,
        file_size: file.size,
        metadata: { "bulk_upload" => true }
      )
      document.file.attach(file)
      
      if document.save
        success_count += 1
      else
        error_count += 1
        errors << "#{file.original_filename}: #{document.errors.full_messages.join(', ')}"
      end
    end

    if error_count > 0
      flash[:alert] = "#{success_count} documents uploaded successfully. #{error_count} failed: #{errors.join('; ')}"
    else
      flash[:notice] = "#{success_count} documents uploaded successfully!"
    end

    redirect_to documents_path
  end

  def bulk_actions
    action = params[:bulk_action]
    document_ids = params[:document_ids] || []

    if document_ids.empty?
      redirect_to documents_path, alert: "No documents selected."
      return
    end

    documents = Current.tenant.documents.where(id: document_ids)

    case action
    when "approve"
      documents.update_all(status: "approved")
      redirect_to documents_path, notice: "#{documents.count} documents approved."
    when "reject"
      documents.update_all(status: "requires_review")
      redirect_to documents_path, notice: "#{documents.count} documents sent for review."
    when "delete"
      documents.destroy_all
      redirect_to documents_path, notice: "#{documents.count} documents deleted."
    when "reprocess"
      documents.each { |doc| DocumentProcessorJob.perform_later(doc) if doc.extraction_template.present? }
      redirect_to documents_path, notice: "#{documents.count} documents queued for reprocessing."
    else
      redirect_to documents_path, alert: "Invalid action."
    end
  end

  def export
    @documents = Current.tenant.documents.includes(:user, :extraction_template)
    
    respond_to do |format|
      format.csv { send_data generate_csv(@documents), filename: "documents-#{Date.current}.csv" }
      format.xlsx { send_data generate_xlsx(@documents), filename: "documents-#{Date.current}.xlsx" }
    end
  end

  private

  def set_document
    @document = Current.tenant.documents.find(params[:id])
  end

  def document_params
    params.require(:document).permit(:name, :description, :file, :extraction_template_id, :metadata)
  end

  def generate_csv(documents)
    require 'csv'
    
    CSV.generate(headers: true) do |csv|
      csv << ['ID', 'Name', 'Status', 'Template', 'Created By', 'Created At', 'Processed At', 'Extracted Data']
      
      documents.each do |doc|
        csv << [
          doc.id,
          doc.name,
          doc.status,
          doc.extraction_template&.name,
          doc.user.name,
          doc.created_at.strftime("%Y-%m-%d %H:%M"),
          doc.processing_completed_at&.strftime("%Y-%m-%d %H:%M"),
          doc.extracted_data.to_json
        ]
      end
    end
  end

  def generate_xlsx(documents)
    # For now, we'll use CSV format
    # In production, you'd use a gem like caxlsx or write_xlsx
    generate_csv(documents)
  end
end