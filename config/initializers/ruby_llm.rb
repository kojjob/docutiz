# Configure RubyLLM with default settings
# Individual API calls can override these settings

RubyLLM.configure do |config|
  # API Keys from credentials or environment
  config.openai_api_key = Rails.application.credentials.dig(:openai, :api_key) || ENV['OPENAI_API_KEY']
  config.anthropic_api_key = Rails.application.credentials.dig(:anthropic, :api_key) || ENV['ANTHROPIC_API_KEY']
  
  # Google configuration if available
  if google_key = Rails.application.credentials.dig(:google, :api_key) || ENV['GOOGLE_API_KEY']
    config.google_api_key = google_key
  end
  
  # Logging in development
  if Rails.env.development?
    config.logger = Rails.logger
  end
end