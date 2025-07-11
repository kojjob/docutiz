# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create a demo tenant and user for development
if Rails.env.development?
  # Create demo tenant
  demo_tenant = Tenant.find_or_create_by!(subdomain: 'demo') do |t|
    t.name = 'Demo Company'
    t.plan = 'trial'
    t.trial_ends_at = 14.days.from_now
    t.settings = {
      max_users: 5,
      max_documents_per_month: 1000,
      features: [ 'basic_extraction', 'templates', 'api_access' ]
    }
  end

  puts "Created tenant: #{demo_tenant.name} (#{demo_tenant.subdomain}.localhost:3000)"

  # Create demo user
  demo_user = User.find_or_create_by!(email: 'demo@example.com', tenant: demo_tenant) do |u|
    u.name = 'Demo User'
    u.password = 'password123'
    u.password_confirmation = 'password123'
    u.role = :owner
    u.confirmed_at = Time.current # Skip email confirmation
  end

  puts "Created user: #{demo_user.email} (password: password123)"
  puts "Access the app at: http://demo.localhost:3000"

  # Create additional team members
  [ 'Alice Developer', 'Bob Manager' ].each_with_index do |name, i|
    email = "#{name.split.first.downcase}@example.com"
    User.find_or_create_by!(email: email, tenant: demo_tenant) do |u|
      u.name = name
      u.password = 'password123'
      u.password_confirmation = 'password123'
      u.role = i == 0 ? :admin : :member
      u.confirmed_at = Time.current
    end
    puts "Created user: #{email}"
  end

  # Create extraction templates
  invoice_template = ExtractionTemplate.find_or_create_by!(
    tenant: demo_tenant,
    name: 'Standard Invoice'
  ) do |t|
    t.description = 'Extract key information from invoices'
    t.document_type = 'invoice'
    t.fields = [
      { 'name' => 'invoice_number', 'type' => 'string', 'required' => true, 'description' => 'Invoice number or ID' },
      { 'name' => 'invoice_date', 'type' => 'date', 'required' => true, 'description' => 'Date of the invoice' },
      { 'name' => 'due_date', 'type' => 'date', 'required' => false, 'description' => 'Payment due date' },
      { 'name' => 'vendor_name', 'type' => 'string', 'required' => true, 'description' => 'Name of the vendor/supplier' },
      { 'name' => 'vendor_address', 'type' => 'string', 'required' => false, 'description' => 'Address of the vendor' },
      { 'name' => 'customer_name', 'type' => 'string', 'required' => false, 'description' => 'Name of the customer' },
      { 'name' => 'subtotal', 'type' => 'currency', 'required' => true, 'description' => 'Subtotal amount' },
      { 'name' => 'tax_amount', 'type' => 'currency', 'required' => false, 'description' => 'Tax amount' },
      { 'name' => 'total_amount', 'type' => 'currency', 'required' => true, 'description' => 'Total amount to pay' },
      { 'name' => 'line_items', 'type' => 'array', 'required' => false, 'description' => 'Individual line items' }
    ]
    t.prompt_template = <<~PROMPT
      Please extract the following information from this invoice:

      {{fields_list}}

      Return the data in JSON format with the field names as keys.
      For currency fields, extract just the numeric value.
      For dates, use YYYY-MM-DD format.
      If a field is not found, use null.
    PROMPT
    t.settings = {
      'confidence_threshold' => 0.85,
      'require_human_review' => false,
      'auto_approve' => true,
      'ai_provider' => 'openai',
      'ai_model' => 'gpt-4o-mini'
    }
  end

  puts "Created extraction template: #{invoice_template.name}"

  receipt_template = ExtractionTemplate.find_or_create_by!(
    tenant: demo_tenant,
    name: 'Receipt Extractor'
  ) do |t|
    t.description = 'Extract information from receipts'
    t.document_type = 'receipt'
    t.fields = [
      { 'name' => 'merchant_name', 'type' => 'string', 'required' => true, 'description' => 'Name of the merchant' },
      { 'name' => 'transaction_date', 'type' => 'date', 'required' => true, 'description' => 'Date of transaction' },
      { 'name' => 'total_amount', 'type' => 'currency', 'required' => true, 'description' => 'Total amount' },
      { 'name' => 'payment_method', 'type' => 'string', 'required' => false, 'description' => 'Payment method used' },
      { 'name' => 'items', 'type' => 'array', 'required' => false, 'description' => 'List of items purchased' }
    ]
    t.prompt_template = <<~PROMPT
      Extract receipt information:
      {{fields_list}}

      Format as JSON. Use null for missing fields.
    PROMPT
    t.settings = {
      'confidence_threshold' => 0.8,
      'require_human_review' => false,
      'auto_approve' => true,
      'ai_provider' => 'anthropic',
      'ai_model' => 'claude-3-haiku-20240307'
    }
  end

  puts "Created extraction template: #{receipt_template.name}"
end
