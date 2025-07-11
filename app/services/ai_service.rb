class AiService
  class << self
    def extract_document_data(document, provider: nil, model: nil)
      # Get extraction template
      template = document.extraction_template
      return {} unless template
      
      # Get the document content
      document_content = get_document_content(document)
      
      # Build prompt from template
      prompt = build_extraction_prompt(template, document)
      
      # Create chat instance based on provider
      chat = create_chat_instance(provider || default_provider, model)
      
      # Extract data - ruby_llm handles both text and images
      response = if document_content[:image]
        chat.ask(prompt, image: document_content[:image])
      else
        chat.ask(prompt)
      end
      
      # Parse response
      extracted_data = parse_json_response(response.content)
      
      # Store extraction results with confidence scores
      store_extraction_results(document, extracted_data, provider || default_provider, model || 'default')
      
      extracted_data
    rescue StandardError => e
      Rails.logger.error "AI extraction failed: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise "AI service error: #{e.message}"
    end

    private

    def create_chat_instance(provider_name, model = nil)
      case provider_name.to_sym
      when :openai
        api_key = get_api_key(:openai)
        RubyLLM.chat(openai_api_key: api_key, model: model || 'gpt-4o-mini')
      when :anthropic
        api_key = get_api_key(:anthropic)
        RubyLLM.chat(anthropic_api_key: api_key, model: model || 'claude-3-haiku-20240307')
      when :google
        api_key = get_api_key(:google)
        RubyLLM.chat(google_api_key: api_key, model: model || 'gemini-1.5-flash')
      else
        # Default to OpenAI
        RubyLLM.chat(model: model)
      end
    end

    def default_provider
      ENV['DEFAULT_AI_PROVIDER']&.to_sym || :openai
    end

    def get_api_key(provider_name)
      key = case provider_name.to_sym
      when :openai
        Rails.application.credentials.dig(:openai, :api_key) || ENV['OPENAI_API_KEY']
      when :anthropic
        Rails.application.credentials.dig(:anthropic, :api_key) || ENV['ANTHROPIC_API_KEY']
      when :google
        Rails.application.credentials.dig(:google, :api_key) || ENV['GOOGLE_API_KEY']
      when :deepseek
        Rails.application.credentials.dig(:deepseek, :api_key) || ENV['DEEPSEEK_API_KEY']
      end
      
      raise ArgumentError, "API key not configured for #{provider_name}" unless key
      key
    end

    def get_document_content(document)
      if document.has_file?
        if document.file.image?
          { image: document.file_url }
        else
          # For PDFs, we'd need to convert to images or extract text
          { text: extract_text_from_pdf(document) }
        end
      else
        { text: "" }
      end
    end

    def extract_text_from_pdf(document)
      # Simple PDF text extraction
      return "" unless document.file.content_type == "application/pdf"
      
      tempfile = Tempfile.new(['document', '.pdf'])
      tempfile.binmode
      tempfile.write(document.file.download)
      tempfile.rewind
      
      reader = PDF::Reader.new(tempfile.path)
      text = reader.pages.map(&:text).join("\n")
      
      tempfile.close
      tempfile.unlink
      
      text
    rescue StandardError => e
      Rails.logger.error "PDF extraction failed: #{e.message}"
      ""
    end

    def build_extraction_prompt(template, document)
      field_descriptions = template.fields.map do |field|
        "- #{field['name']}: #{field['description']} (type: #{field['type']}, required: #{field['required']})"
      end.join("\n")

      <<~PROMPT
        You are a document data extraction specialist. Extract structured data from this #{template.document_type}.
        
        Document name: #{document.name}
        
        #{template.prompt_template}
        
        Please extract the following fields:
        #{field_descriptions}

        Return the extracted data as a JSON object with the field names as keys.
        For missing required fields, use null.
        For currency fields, extract numeric values only (no symbols).
        For date fields, use YYYY-MM-DD format.
        For array fields, return an array of values.

        Respond ONLY with valid JSON, no additional text.
      PROMPT
    end

    def parse_json_response(response_text)
      # Try to extract JSON from the response
      json_match = response_text.match(/\{.*\}/m)
      return {} unless json_match

      begin
        JSON.parse(json_match[0])
      rescue JSON::ParserError => e
        Rails.logger.error "Failed to parse AI response as JSON: #{e.message}"
        Rails.logger.error "Response was: #{response_text}"
        {}
      end
    end

    def store_extraction_results(document, extracted_data, provider, model)
      extracted_data.each do |field_name, field_value|
        # Calculate confidence based on field presence and type
        confidence = calculate_confidence(field_name, field_value, document.extraction_template)
        
        document.extraction_results.create!(
          field_name: field_name,
          field_value: field_value.to_s,
          confidence_score: confidence,
          ai_model: "#{provider}_#{model}",
          raw_response: { extracted_value: field_value }
        )
      end
    end

    def calculate_confidence(field_name, field_value, template)
      # Simple confidence calculation
      field_config = template.fields.find { |f| f['name'] == field_name }
      return 0.5 unless field_config
      
      # Higher confidence for required fields that are present
      base_confidence = field_value.present? ? 0.8 : 0.3
      base_confidence += 0.1 if field_config['required'] && field_value.present?
      
      [base_confidence, 1.0].min
    end
  end
end