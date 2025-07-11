# Service for integrating Claude Code SDK capabilities
# This service leverages Claude Code to generate code, optimize prompts,
# and provide intelligent assistance for document processing
class ClaudeCodeService
  class << self
    # Generate an extraction template from a sample document
    def generate_extraction_template(sample_document, description, user_requirements = nil)
      prompt = build_template_generation_prompt(sample_document, description, user_requirements)
      
      response = execute_claude_code_query(prompt, max_turns: 3)
      
      parse_template_response(response)
    rescue StandardError => e
      Rails.logger.error "Failed to generate template: #{e.message}"
      raise
    end
    
    # Optimize extraction prompts based on historical performance
    def optimize_extraction_prompt(current_prompt, failed_extractions, successful_extractions)
      analysis_prompt = build_prompt_optimization_request(
        current_prompt, 
        failed_extractions, 
        successful_extractions
      )
      
      response = execute_claude_code_query(analysis_prompt)
      
      parse_optimized_prompt(response)
    end
    
    # Generate API endpoint code based on requirements
    def generate_api_endpoint(requirements, existing_patterns = nil)
      generation_prompt = build_api_generation_prompt(requirements, existing_patterns)
      
      response = execute_claude_code_query(generation_prompt, max_turns: 5)
      
      parse_generated_code(response)
    end
    
    # Generate data transformation code for webhooks
    def generate_webhook_transformer(source_format, target_format, sample_data = nil)
      transform_prompt = build_transformation_prompt(source_format, target_format, sample_data)
      
      response = execute_claude_code_query(transform_prompt)
      
      parse_transformation_code(response)
    end
    
    # Analyze document and suggest pre-processing steps
    def analyze_document_quality(document_sample, document_type)
      analysis_prompt = build_quality_analysis_prompt(document_sample, document_type)
      
      response = execute_claude_code_query(analysis_prompt)
      
      parse_quality_recommendations(response)
    end
    
    # Generate migration scripts from competitor platforms
    def generate_migration_script(source_platform, data_sample, mapping_rules = nil)
      migration_prompt = build_migration_prompt(source_platform, data_sample, mapping_rules)
      
      response = execute_claude_code_query(migration_prompt, max_turns: 4)
      
      parse_migration_script(response)
    end
    
    private
    
    def execute_claude_code_query(prompt, options = {})
      # In a real implementation, this would use the Claude Code SDK
      # For now, we'll prepare the structure for when the SDK is available
      
      # Example implementation when SDK is available:
      # require 'claude_code_sdk'
      # 
      # ClaudeCode.query(
      #   prompt: prompt,
      #   model: 'claude-3-opus',
      #   max_turns: options[:max_turns] || 1,
      #   temperature: options[:temperature] || 0.7
      # )
      
      # Placeholder response for development
      {
        status: 'success',
        content: 'Generated code would appear here',
        metadata: { model: 'claude-3-opus', turns: 1 }
      }
    end
    
    def build_template_generation_prompt(sample_document, description, user_requirements)
      <<~PROMPT
        You are an expert at analyzing documents and creating extraction templates.
        
        Document Description: #{description}
        
        Sample Document Content:
        #{sample_document}
        
        User Requirements:
        #{user_requirements || 'Extract all relevant fields automatically'}
        
        Please analyze this document and generate:
        1. A complete extraction template with field definitions
        2. Optimized prompts for each field
        3. Validation rules for each field
        4. Sample test cases
        
        Return the template in JSON format compatible with our ExtractionTemplate model.
      PROMPT
    end
    
    def build_prompt_optimization_request(current_prompt, failed_extractions, successful_extractions)
      <<~PROMPT
        Analyze and optimize this extraction prompt based on performance data.
        
        Current Prompt:
        #{current_prompt}
        
        Failed Extractions (#{failed_extractions.count} samples):
        #{failed_extractions.to_json}
        
        Successful Extractions (#{successful_extractions.count} samples):
        #{successful_extractions.to_json}
        
        Generate an improved prompt that:
        1. Addresses common failure patterns
        2. Maintains successful extraction patterns
        3. Improves clarity and specificity
        4. Optimizes for the AI model being used
      PROMPT
    end
    
    def build_api_generation_prompt(requirements, existing_patterns)
      <<~PROMPT
        Generate a complete Rails API endpoint based on these requirements.
        
        Requirements:
        #{requirements}
        
        Existing Code Patterns:
        #{existing_patterns || 'Follow Rails best practices'}
        
        Generate:
        1. Controller with all necessary actions
        2. Request/response serializers
        3. Authentication and authorization
        4. Complete test suite
        5. API documentation
        
        Follow RESTful conventions and include error handling.
      PROMPT
    end
    
    def build_transformation_prompt(source_format, target_format, sample_data)
      <<~PROMPT
        Generate a data transformation service for webhook integration.
        
        Source Format:
        #{source_format}
        
        Target Format:
        #{target_format}
        
        Sample Data:
        #{sample_data}
        
        Create a Ruby service that:
        1. Validates incoming data
        2. Transforms fields according to mapping
        3. Handles errors gracefully
        4. Includes comprehensive tests
      PROMPT
    end
    
    def build_quality_analysis_prompt(document_sample, document_type)
      <<~PROMPT
        Analyze this document sample and recommend pre-processing steps.
        
        Document Type: #{document_type}
        Sample: #{document_sample}
        
        Provide recommendations for:
        1. Image quality improvements
        2. OCR optimization settings
        3. Pre-processing steps (rotation, cropping, etc.)
        4. Confidence thresholds
        5. Specific extraction strategies
      PROMPT
    end
    
    def build_migration_prompt(source_platform, data_sample, mapping_rules)
      <<~PROMPT
        Generate a migration script to import data from #{source_platform}.
        
        Sample Data Structure:
        #{data_sample}
        
        Mapping Rules:
        #{mapping_rules || 'Automatically map fields based on similarity'}
        
        Generate:
        1. Data transformation script
        2. Validation logic
        3. Error handling and rollback
        4. Progress tracking
        5. Test coverage
      PROMPT
    end
    
    def parse_template_response(response)
      # Parse Claude Code response and extract template JSON
      response[:content]
    end
    
    def parse_optimized_prompt(response)
      # Extract optimized prompt from response
      response[:content]
    end
    
    def parse_generated_code(response)
      # For now, generate sample code until Claude Code SDK is available
      # This demonstrates the expected output format
      {
        controller: generate_sample_controller_code,
        serializer: generate_sample_serializer_code,
        tests: generate_sample_test_code,
        documentation: generate_sample_documentation
      }
    end
    
    def parse_transformation_code(response)
      # Extract transformation service code
      response[:content]
    end
    
    def parse_quality_recommendations(response)
      # Parse and structure quality recommendations
      response[:content]
    end
    
    def parse_migration_script(response)
      # Extract migration script and instructions
      response[:content]
    end
    
    def extract_controller_code(response)
      # Extract controller code from response
      response[:content].match(/class.*Controller.*?end/m)&.to_s || ''
    end
    
    def extract_serializer_code(response)
      # Extract serializer code from response
      response[:content].match(/class.*Serializer.*?end/m)&.to_s || ''
    end
    
    def extract_test_code(response)
      # Extract test code from response
      response[:content].match(/RSpec\.describe.*?end/m)&.to_s || ''
    end
    
    def extract_documentation(response)
      # Extract API documentation from response
      response[:content].match(/# API Documentation.*?(?=\n\n)/m)&.to_s || ''
    end
    
    # Temporary sample code generators until Claude Code SDK is available
    def generate_sample_controller_code
      <<~RUBY
        class Api::V1::DocumentExtractionsController < Api::V1::BaseController
          before_action :set_document, only: [:show, :status]
          
          # POST /api/v1/document_extractions
          # Upload and extract data from a document
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
          # Get extracted data for a document
          def show
            if @document.processed?
              render json: {
                id: @document.id,
                status: @document.status,
                extracted_data: @document.extracted_data,
                metadata: {
                  extracted_at: @document.processed_at,
                  confidence_scores: @document.confidence_scores,
                  document_type: @document.document_type
                }
              }
            else
              render json: {
                id: @document.id,
                status: @document.status,
                message: status_message(@document)
              }
            end
          end
          
          # GET /api/v1/document_extractions/:id/status
          # Check extraction status
          def status
            render json: {
              id: @document.id,
              status: @document.status,
              progress: @document.processing_progress,
              message: status_message(@document)
            }
          end
          
          # POST /api/v1/document_extractions/batch
          # Upload multiple documents for extraction
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
              batch_status_url: api_v1_batch_status_url(documents.map(&:id))
            }, status: :created
          end
          
          private
          
          def set_document
            @document = Current.tenant.documents.find(params[:id])
          rescue ActiveRecord::RecordNotFound
            render json: { error: 'Document not found' }, status: :not_found
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
          
        end
      RUBY
    end
    
    def generate_sample_serializer_code
      <<~RUBY
        class DocumentExtractionSerializer
          include JSONAPI::Serializer
          
          attributes :id, :name, :status, :document_type, :created_at, :processed_at
          
          attribute :file_url do |document|
            Rails.application.routes.url_helpers.rails_blob_url(document.file) if document.file.attached?
          end
          
          attribute :extracted_data do |document|
            document.extracted_data if document.processed?
          end
          
          attribute :confidence_scores do |document|
            document.confidence_scores if document.processed?
          end
          
          attribute :processing_time do |document|
            if document.processed_at && document.created_at
              (document.processed_at - document.created_at).round(2)
            end
          end
          
          attribute :extraction_template do |document|
            if document.extraction_template
              {
                id: document.extraction_template.id,
                name: document.extraction_template.name,
                document_type: document.extraction_template.document_type
              }
            end
          end
          
          belongs_to :user
          belongs_to :extraction_template, optional: true
        end
      RUBY
    end
    
    def generate_sample_test_code
      <<~RUBY
        require 'rails_helper'
        
        RSpec.describe Api::V1::DocumentExtractionsController, type: :request do
          let(:tenant) { create(:tenant) }
          let(:user) { create(:user, :with_api_token, tenant: tenant) }
          let(:headers) { { 'Authorization' => "Bearer #{user.api_token}" } }
          let(:extraction_template) { create(:extraction_template, tenant: tenant) }
          
          before do
            host! "#{tenant.subdomain}.example.com"
          end
          
          describe 'POST /api/v1/document_extractions' do
            let(:valid_file) { fixture_file_upload('invoice_sample.pdf', 'application/pdf') }
            let(:valid_params) do
              {
                document: {
                  file: valid_file,
                  name: 'Test Invoice',
                  extraction_template_id: extraction_template.id
                }
              }
            end
            
            context 'with valid parameters' do
              it 'creates a new document and queues extraction' do
                expect {
                  post '/api/v1/document_extractions', params: valid_params, headers: headers
                }.to change(Document, :count).by(1)
                  .and have_enqueued_job(DocumentProcessorJob)
                
                expect(response).to have_http_status(:created)
                expect(json_response['status']).to eq('processing')
                expect(json_response['polling_url']).to be_present
              end
            end
            
            context 'with invalid file type' do
              it 'returns validation error' do
                invalid_file = fixture_file_upload('test.txt', 'text/plain')
                invalid_params = valid_params.deep_merge(document: { file: invalid_file })
                
                post '/api/v1/document_extractions', params: invalid_params, headers: headers
                
                expect(response).to have_http_status(:unprocessable_entity)
                expect(json_response['errors']).to include('File must be PDF or image format')
              end
            end
          end
          
          describe 'GET /api/v1/document_extractions/:id' do
            context 'when document is processed' do
              let(:document) do
                create(:document, 
                  tenant: tenant,
                  status: 'processed',
                  extracted_data: { 
                    invoice_number: 'INV-001',
                    total_amount: 150.00,
                    vendor_name: 'Acme Corp'
                  }
                )
              end
              
              it 'returns extracted data' do
                get "/api/v1/document_extractions/#{document.id}", headers: headers
                
                expect(response).to have_http_status(:ok)
                expect(json_response['status']).to eq('processed')
                expect(json_response['extracted_data']).to include('invoice_number' => 'INV-001')
              end
            end
            
            context 'when document is still processing' do
              let(:document) { create(:document, tenant: tenant, status: 'processing') }
              
              it 'returns processing status' do
                get "/api/v1/document_extractions/#{document.id}", headers: headers
                
                expect(response).to have_http_status(:ok)
                expect(json_response['status']).to eq('processing')
                expect(json_response['extracted_data']).to be_nil
              end
            end
          end
          
          describe 'POST /api/v1/document_extractions/batch' do
            let(:files) do
              [
                fixture_file_upload('invoice1.pdf', 'application/pdf'),
                fixture_file_upload('invoice2.pdf', 'application/pdf')
              ]
            end
            
            it 'creates multiple documents' do
              params = {
                documents: files.map do |file|
                  { file: file, template_id: extraction_template.id }
                end
              }
              
              expect {
                post '/api/v1/document_extractions/batch', params: params, headers: headers
              }.to change(Document, :count).by(2)
                .and have_enqueued_job(DocumentProcessorJob).twice
              
              expect(response).to have_http_status(:created)
              expect(json_response['created'].size).to eq(2)
              expect(json_response['batch_status_url']).to be_present
            end
          end
        end
      RUBY
    end
    
    def generate_sample_documentation
      <<~MARKDOWN
        # Document Extraction API Documentation
        
        ## Overview
        The Docutiz Document Extraction API allows you to programmatically upload documents and extract structured data using advanced AI models. Perfect for automating invoice processing, receipt scanning, and document digitization workflows.
        
        ## Authentication
        All endpoints require a valid API token in the Authorization header:
        ```
        Authorization: Bearer YOUR_API_TOKEN
        ```
        
        To generate an API token, visit your account settings in the Docutiz dashboard.
        
        ## Base URL
        ```
        https://your-tenant.docutiz.com/api/v1
        ```
        
        ## Endpoints
        
        ### Upload and Extract Document
        ```
        POST /api/v1/document_extractions
        ```
        
        **Request Body (multipart/form-data):**
        - `document[file]` (required): The document file (PDF, JPG, PNG)
        - `document[name]` (optional): Custom name for the document
        - `document[extraction_template_id]` (optional): ID of extraction template to use
        - `document[metadata]` (optional): Additional metadata as JSON
        
        **Example using cURL:**
        ```bash
        curl -X POST https://your-tenant.docutiz.com/api/v1/document_extractions \\
          -H "Authorization: Bearer YOUR_API_TOKEN" \\
          -F "document[file]=@invoice.pdf" \\
          -F "document[name]=Invoice #12345" \\
          -F "document[extraction_template_id]=template_123"
        ```
        
        **Response:**
        ```json
        {
          "id": "doc_abc123",
          "status": "processing",
          "message": "Document uploaded successfully. Extraction in progress.",
          "polling_url": "https://your-tenant.docutiz.com/api/v1/document_extractions/doc_abc123/status"
        }
        ```
        
        ### Get Extraction Results
        ```
        GET /api/v1/document_extractions/:id
        ```
        
        **Response (when processed):**
        ```json
        {
          "id": "doc_abc123",
          "status": "processed",
          "extracted_data": {
            "invoice_number": "INV-2024-001",
            "vendor_name": "Acme Corporation",
            "invoice_date": "2024-01-15",
            "due_date": "2024-02-15",
            "total_amount": 1250.00,
            "tax_amount": 125.00,
            "line_items": [
              {
                "description": "Professional Services",
                "quantity": 10,
                "unit_price": 100.00,
                "amount": 1000.00
              }
            ]
          },
          "metadata": {
            "extracted_at": "2024-01-15T10:30:00Z",
            "confidence_scores": {
              "invoice_number": 0.98,
              "vendor_name": 0.95,
              "total_amount": 0.99
            },
            "document_type": "invoice"
          }
        }
        ```
        
        ### Check Extraction Status
        ```
        GET /api/v1/document_extractions/:id/status
        ```
        
        **Response:**
        ```json
        {
          "id": "doc_abc123",
          "status": "processing",
          "progress": 65,
          "message": "Extraction in progress"
        }
        ```
        
        ### Batch Upload Documents
        ```
        POST /api/v1/document_extractions/batch
        ```
        
        Upload multiple documents for extraction in a single request.
        
        **Request Body (multipart/form-data):**
        ```
        documents[0][file]: invoice1.pdf
        documents[0][template_id]: template_123
        documents[1][file]: receipt1.jpg
        documents[1][template_id]: template_456
        ```
        
        **Response:**
        ```json
        {
          "created": [
            { "id": "doc_abc123", "name": "invoice1.pdf" },
            { "id": "doc_def456", "name": "receipt1.jpg" }
          ],
          "errors": [],
          "batch_status_url": "https://your-tenant.docutiz.com/api/v1/batch_status?ids=doc_abc123,doc_def456"
        }
        ```
        
        ## Extraction Templates
        
        Extraction templates define which fields to extract for different document types:
        
        - **Invoice Template**: invoice_number, vendor_name, dates, amounts, line_items
        - **Receipt Template**: merchant_name, date, total, payment_method
        - **Bank Statement**: account_number, transactions, balance
        - **Contract Template**: parties, dates, terms, signatures
        
        ## Webhooks
        
        Configure webhooks to receive real-time notifications when extraction completes:
        
        ```json
        {
          "event": "document.processed",
          "timestamp": "2024-01-15T10:30:00Z",
          "document_id": "doc_abc123",
          "status": "processed",
          "extracted_data": { ... }
        }
        ```
        
        ## Error Handling
        
        The API uses standard HTTP status codes:
        
        - `200 OK` - Success
        - `201 Created` - Document created successfully
        - `400 Bad Request` - Invalid request parameters
        - `401 Unauthorized` - Invalid or missing API token
        - `404 Not Found` - Document not found
        - `422 Unprocessable Entity` - Validation errors
        - `429 Too Many Requests` - Rate limit exceeded
        - `500 Internal Server Error` - Server error
        
        **Error Response Format:**
        ```json
        {
          "errors": [
            "File must be PDF or image format",
            "File size cannot exceed 10MB"
          ]
        }
        ```
        
        ## Rate Limits
        
        - **Standard Plan**: 100 requests per minute
        - **Pro Plan**: 500 requests per minute
        - **Enterprise**: Custom limits
        
        ## SDKs and Libraries
        
        Official SDKs available for:
        - Ruby: `gem install docutiz`
        - Python: `pip install docutiz`
        - Node.js: `npm install @docutiz/sdk`
        - PHP: `composer require docutiz/sdk`
      MARKDOWN
    end
  end
end