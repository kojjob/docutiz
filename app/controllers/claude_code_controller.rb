class ClaudeCodeController < ApplicationController
  layout 'dashboard'
  before_action :authenticate_user!
  before_action :check_permissions
  
  # Show the API builder interface
  def api_builder
    # Render the API builder view
  end
  
  # Test page for Stimulus debugging
  def test
    # Render test view
  end
  
  # Generate extraction template from sample document
  def generate_template
    sample_content = params[:sample_content]
    description = params[:description]
    requirements = params[:requirements]
    
    result = ClaudeCodeService.generate_extraction_template(
      sample_content,
      description,
      requirements
    )
    
    render json: { 
      status: 'success', 
      template: result,
      message: 'Template generated successfully'
    }
  rescue StandardError => e
    render json: { 
      status: 'error', 
      message: e.message 
    }, status: :unprocessable_entity
  end
  
  # Optimize extraction prompt
  def optimize_prompt
    template = Current.tenant.extraction_templates.find(params[:template_id])
    
    # Get recent extraction results for analysis
    failed_extractions = template.extraction_results
                                .joins(:document)
                                .where('confidence_score < ?', 0.7)
                                .limit(10)
                                .pluck(:field_name, :field_value, :raw_response)
    
    successful_extractions = template.extraction_results
                                    .joins(:document)
                                    .where('confidence_score >= ?', 0.9)
                                    .limit(10)
                                    .pluck(:field_name, :field_value, :raw_response)
    
    optimized_prompt = ClaudeCodeService.optimize_extraction_prompt(
      template.prompt_template,
      failed_extractions,
      successful_extractions
    )
    
    render json: {
      status: 'success',
      original_prompt: template.prompt_template,
      optimized_prompt: optimized_prompt,
      analysis: {
        failed_count: failed_extractions.count,
        successful_count: successful_extractions.count
      }
    }
  rescue StandardError => e
    render json: { 
      status: 'error', 
      message: e.message 
    }, status: :unprocessable_entity
  end
  
  # Generate API endpoint
  def generate_api
    requirements = params[:requirements]
    resource_name = params[:resource_name]
    
    # Get existing patterns from current codebase
    existing_patterns = {
      authentication: 'JWT',
      serialization: 'jsonapi-serializer',
      testing: 'RSpec'
    }
    
    generated_code = ClaudeCodeService.generate_api_endpoint(
      requirements,
      existing_patterns
    )
    
    render json: {
      status: 'success',
      generated_code: generated_code,
      instructions: generate_implementation_instructions(generated_code)
    }
  rescue StandardError => e
    render json: { 
      status: 'error', 
      message: e.message 
    }, status: :unprocessable_entity
  end
  
  # Analyze document quality
  def analyze_quality
    document = Current.tenant.documents.find(params[:document_id])
    
    # Get document preview or sample
    sample = if document.file.image?
               document.file.url
             else
               document.extracted_data.to_json
             end
    
    recommendations = ClaudeCodeService.analyze_document_quality(
      sample,
      document.extraction_template&.document_type || 'unknown'
    )
    
    render json: {
      status: 'success',
      document_id: document.id,
      recommendations: recommendations
    }
  rescue StandardError => e
    render json: { 
      status: 'error', 
      message: e.message 
    }, status: :unprocessable_entity
  end
  
  # Generate webhook transformer
  def generate_webhook
    source_format = params[:source_format]
    target_format = params[:target_format]
    sample_data = params[:sample_data]
    
    transformer_code = ClaudeCodeService.generate_webhook_transformer(
      source_format,
      target_format,
      sample_data
    )
    
    render json: {
      status: 'success',
      transformer_code: transformer_code,
      test_endpoint: generate_test_webhook_url
    }
  rescue StandardError => e
    render json: { 
      status: 'error', 
      message: e.message 
    }, status: :unprocessable_entity
  end
  
  # Generate migration script
  def generate_migration
    source_platform = params[:source_platform]
    data_sample = params[:data_sample]
    mapping_rules = params[:mapping_rules]
    
    migration_script = ClaudeCodeService.generate_migration_script(
      source_platform,
      data_sample,
      mapping_rules
    )
    
    render json: {
      status: 'success',
      migration_script: migration_script,
      estimated_time: estimate_migration_time(data_sample)
    }
  rescue StandardError => e
    render json: { 
      status: 'error', 
      message: e.message 
    }, status: :unprocessable_entity
  end
  
  private
  
  def check_permissions
    # Only admins and owners can use Claude Code features
    unless current_user.admin? || current_user.owner?
      render json: { 
        status: 'error', 
        message: 'Insufficient permissions' 
      }, status: :forbidden
    end
  end
  
  def generate_implementation_instructions(generated_code)
    {
      steps: [
        "Review the generated code for your specific requirements",
        "Create the controller file in app/controllers/api/v1/",
        "Add the serializer to app/serializers/",
        "Add routes to config/routes.rb",
        "Run the generated tests to ensure everything works",
        "Update API documentation"
      ],
      files_to_create: generated_code.keys.map { |k| "#{k}.rb" }
    }
  end
  
  def generate_test_webhook_url
    "#{request.base_url}/webhooks/test/#{SecureRandom.hex(8)}"
  end
  
  def estimate_migration_time(data_sample)
    # Simple estimation based on sample size
    sample_size = data_sample.to_s.size
    if sample_size < 1000
      "Less than 1 minute"
    elsif sample_size < 10000
      "1-5 minutes"
    else
      "5-15 minutes"
    end
  end
end