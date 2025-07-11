class ExtractionTemplatesController < ApplicationController
  include Pagy::Backend
  
  layout 'dashboard'
  before_action :authenticate_user!
  before_action :set_extraction_template, only: [:show, :edit, :update, :destroy, :duplicate, :test, :export]

  def index
    @pagy, @templates = pagy(
      Current.tenant.extraction_templates
        .includes(:documents)
        .order(created_at: :desc)
    )
    
    # Group templates by document type for better organization
    @templates_by_type = @templates.group_by(&:document_type)
    
    # Calculate statistics
    @stats = {
      total_templates: Current.tenant.extraction_templates.count,
      active_templates: Current.tenant.extraction_templates.active.count,
      total_extractions: Current.tenant.documents.completed.count,
      success_rate: calculate_overall_success_rate
    }
  end

  def show
    # Load recent extractions using this template
    @recent_extractions = @extraction_template.extraction_results
                                           .includes(:document)
                                           .order(created_at: :desc)
                                           .limit(10)
    
    # Calculate template performance metrics
    @performance = {
      total_uses: @extraction_template.documents.count,
      success_rate: @extraction_template.extraction_success_rate,
      avg_confidence: @extraction_template.average_confidence_score,
      field_accuracy: calculate_field_accuracy(@extraction_template)
    }
  end

  def new
    @extraction_template = Current.tenant.extraction_templates.build
    @extraction_template.fields = default_fields_for_type(params[:document_type])
    @extraction_template.document_type = params[:document_type] if params[:document_type].present?
  end

  def create
    @extraction_template = Current.tenant.extraction_templates.build(extraction_template_params)
    
    if @extraction_template.save
      redirect_to @extraction_template, notice: 'Template created successfully.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # Pre-populate with current values
  end

  def update
    if @extraction_template.update(extraction_template_params)
      redirect_to @extraction_template, notice: 'Template updated successfully.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @extraction_template.documents.exists?
      redirect_to extraction_templates_path, alert: 'Cannot delete template that has been used. Please deactivate it instead.'
    else
      @extraction_template.destroy
      redirect_to extraction_templates_path, notice: 'Template deleted successfully.'
    end
  end

  def duplicate
    new_template = @extraction_template.dup
    new_template.name = "#{@extraction_template.name} (Copy)"
    new_template.active = false # Start as inactive
    
    if new_template.save
      redirect_to edit_extraction_template_path(new_template), 
                  notice: 'Template duplicated successfully. Please review and activate when ready.'
    else
      redirect_to @extraction_template, alert: 'Failed to duplicate template.'
    end
  end

  def test
    # Test extraction with a sample document
    if params[:sample_file].present?
      sample_content = extract_text_from_file(params[:sample_file])
      @test_result = {
        prompt: @extraction_template.generate_prompt(
          document_type: @extraction_template.document_type,
          page_count: 1
        ),
        fields: @extraction_template.fields,
        sample_extraction: simulate_extraction(@extraction_template, sample_content)
      }
      
      render json: @test_result
    else
      render json: { error: 'Please provide a sample file' }, status: :unprocessable_entity
    end
  end

  def export
    # Export template as JSON for sharing or backup
    render json: {
      name: @extraction_template.name,
      document_type: @extraction_template.document_type,
      fields: @extraction_template.fields,
      prompt_template: @extraction_template.prompt_template,
      settings: @extraction_template.settings,
      version: "1.0",
      exported_at: Time.current
    }
  end

  def import
    # Import a template from JSON
    if params[:template_file].present?
      begin
        json_content = params[:template_file].read
        template_data = JSON.parse(json_content)
        
        @extraction_template = Current.tenant.extraction_templates.build(
          name: "#{template_data['name']} (Imported)",
          document_type: template_data['document_type'],
          fields: template_data['fields'],
          prompt_template: template_data['prompt_template'],
          settings: template_data['settings'] || {},
          active: false
        )
        
        if @extraction_template.save
          redirect_to @extraction_template, notice: 'Template imported successfully.'
        else
          redirect_to extraction_templates_path, alert: 'Failed to import template.'
        end
      rescue JSON::ParserError
        redirect_to extraction_templates_path, alert: 'Invalid template file format.'
      end
    else
      redirect_to extraction_templates_path, alert: 'Please select a template file to import.'
    end
  end

  # Template Library - browse pre-made templates
  def library
    @library_templates = load_template_library
    @categories = @library_templates.keys.sort
  end

  # Install a template from the library
  def install_from_library
    template_id = params[:template_id]
    library_template = find_library_template(template_id)
    
    if library_template
      # Check if a template with the same name already exists
      existing_template = Current.tenant.extraction_templates.find_by(name: library_template[:name])
      
      if existing_template
        redirect_to library_extraction_templates_path, alert: "A template with the name '#{library_template[:name]}' already exists."
        return
      end
      
      @extraction_template = Current.tenant.extraction_templates.build(
        name: library_template[:name],
        document_type: library_template[:document_type],
        fields: library_template[:fields],
        prompt_template: library_template[:prompt_template],
        settings: library_template[:settings] || {},
        active: true
      )
      
      if @extraction_template.save
        redirect_to @extraction_template, notice: 'Template installed successfully.'
      else
        error_messages = @extraction_template.errors.full_messages.join(', ')
        redirect_to library_extraction_templates_path, alert: "Failed to install template: #{error_messages}"
      end
    else
      redirect_to library_extraction_templates_path, alert: 'Template not found.'
    end
  end

  private

  def set_extraction_template
    @extraction_template = Current.tenant.extraction_templates.find(params[:id])
  end

  def extraction_template_params
    params.require(:extraction_template).permit(
      :name, 
      :document_type, 
      :prompt_template, 
      :active,
      fields: [:name, :type, :description, :required, :validation_rules, :extraction_hints],
      settings: [:confidence_threshold, :require_human_review, :auto_approve, :language, :output_format]
    )
  end

  def calculate_overall_success_rate
    total = Current.tenant.documents.count
    return 0.0 if total.zero?
    
    # Consider a document successful if it was completed or approved
    successful = Current.tenant.documents.completed.count
    (successful.to_f / total * 100).round(1)
  end

  def calculate_field_accuracy(template)
    results = template.extraction_results.where('confidence_score > ?', 0)
    return {} if results.empty?
    
    field_scores = {}
    template.fields.each do |field|
      field_name = field['name']
      scores = results.pluck(:field_confidences)
                     .compact
                     .map { |fc| fc[field_name] }
                     .compact
      
      if scores.any?
        field_scores[field_name] = (scores.sum.to_f / scores.size * 100).round(1)
      end
    end
    
    field_scores
  end

  def default_fields_for_type(document_type)
    case document_type
    when 'invoice'
      [
        { name: 'invoice_number', type: 'string', description: 'Invoice number or ID', required: true },
        { name: 'invoice_date', type: 'date', description: 'Date of invoice', required: true },
        { name: 'due_date', type: 'date', description: 'Payment due date', required: false },
        { name: 'vendor_name', type: 'string', description: 'Vendor or supplier name', required: true },
        { name: 'vendor_address', type: 'string', description: 'Vendor address', required: false },
        { name: 'customer_name', type: 'string', description: 'Customer or bill-to name', required: false },
        { name: 'subtotal', type: 'number', description: 'Subtotal before tax', required: true },
        { name: 'tax_amount', type: 'number', description: 'Tax amount', required: false },
        { name: 'total_amount', type: 'number', description: 'Total amount due', required: true },
        { name: 'line_items', type: 'array', description: 'Individual line items', required: false }
      ]
    when 'receipt'
      [
        { name: 'merchant_name', type: 'string', description: 'Store or merchant name', required: true },
        { name: 'transaction_date', type: 'date', description: 'Date of purchase', required: true },
        { name: 'total_amount', type: 'number', description: 'Total amount paid', required: true },
        { name: 'payment_method', type: 'string', description: 'Payment method used', required: false },
        { name: 'items', type: 'array', description: 'Purchased items', required: false }
      ]
    when 'bank_statement'
      [
        { name: 'account_number', type: 'string', description: 'Bank account number', required: true },
        { name: 'statement_period', type: 'string', description: 'Statement period', required: true },
        { name: 'beginning_balance', type: 'number', description: 'Starting balance', required: true },
        { name: 'ending_balance', type: 'number', description: 'Ending balance', required: true },
        { name: 'transactions', type: 'array', description: 'List of transactions', required: true }
      ]
    else
      [
        { name: 'field_1', type: 'string', description: 'Custom field 1', required: false }
      ]
    end
  end

  def extract_text_from_file(file)
    # In production, this would use OCR or PDF text extraction
    # For now, return a placeholder
    "Sample document content for testing"
  end

  def simulate_extraction(template, content)
    # Simulate extraction results for testing
    # In production, this would call the AI service
    result = {}
    template.fields.each do |field|
      result[field['name']] = case field['type']
                             when 'number'
                               rand(100..1000)
                             when 'date'
                               Date.today.to_s
                             when 'array'
                               ['Item 1', 'Item 2']
                             else
                               "Sample #{field['name']}"
                             end
    end
    result
  end

  def load_template_library
    # In production, this would load from a database or external service
    # For now, return sample templates
    {
      'Financial' => [
        {
          id: 'invoice_standard',
          name: 'Standard Invoice',
          document_type: 'invoice',
          description: 'Extract key fields from standard invoices',
          fields: default_fields_for_type('invoice'),
          prompt_template: "Extract the following information from this invoice:\n{{fields_list}}\n\nReturn the data as structured JSON."
        },
        {
          id: 'receipt_retail',
          name: 'Retail Receipt',
          document_type: 'receipt',
          description: 'Extract data from retail receipts',
          fields: default_fields_for_type('receipt'),
          prompt_template: "Extract purchase information from this receipt:\n{{fields_list}}\n\nReturn as JSON with amounts as numbers."
        }
      ],
      'Banking' => [
        {
          id: 'bank_statement_standard',
          name: 'Bank Statement',
          document_type: 'bank_statement',
          description: 'Extract transactions and balances from bank statements',
          fields: default_fields_for_type('bank_statement'),
          prompt_template: "Analyze this bank statement and extract:\n{{fields_list}}\n\nFormat transactions as an array with date, description, and amount."
        }
      ]
    }
  end

  def find_library_template(template_id)
    library = load_template_library
    library.values.flatten.find { |t| t[:id] == template_id }
  end
end