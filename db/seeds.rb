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
end
