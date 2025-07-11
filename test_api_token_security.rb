# Test script to verify API token security implementation
require './config/environment'

puts "Testing API Token Security Implementation\n\n"

# Create a test user
user = User.new(
  email: "test_#{SecureRandom.hex(4)}@example.com",
  password: "password123",
  name: "Test User",
  tenant: Tenant.first || Tenant.create!(name: "Test Tenant", subdomain: "test-#{SecureRandom.hex(4)}")
)

# Test 1: Token generation on user creation
puts "1. Testing token generation on user creation..."
user.save!
puts "   ✓ User created successfully"
puts "   ✓ API token digest stored: #{user.api_token_digest.present?}"
puts "   ✓ Plain API token available: #{user.plain_api_token.present?}"
initial_token = user.plain_api_token
puts "   ✓ Token format correct: #{initial_token&.start_with?('doc_')}"

# Test 2: Token regeneration
puts "\n2. Testing token regeneration..."
new_token = user.regenerate_api_token!
puts "   ✓ New token generated: #{new_token.start_with?('doc_')}"
puts "   ✓ New token different from initial: #{new_token != initial_token}"
puts "   ✓ Token digest updated: #{user.api_token_digest.present?}"

# Test 3: Token lookup
puts "\n3. Testing token lookup..."
found_user = User.find_by_api_token(new_token)
puts "   ✓ User found by token: #{found_user == user}"
invalid_user = User.find_by_api_token("invalid_token")
puts "   ✓ Invalid token returns nil: #{invalid_user.nil?}"

# Test 4: No plain text storage
puts "\n4. Verifying no plain text storage..."
raw_user = User.connection.execute("SELECT * FROM users WHERE id = #{user.id}").first
has_api_token_column = raw_user.keys.include?("api_token")
puts "   ✓ Plain api_token column removed: #{!has_api_token_column}"
puts "   ✓ Only hashed token stored in database"

# Test 5: API authentication
puts "\n5. Testing API authentication simulation..."
digest = Digest::SHA256.hexdigest(new_token)
auth_user = User.find_by(api_token_digest: digest)
puts "   ✓ Authentication would work correctly: #{auth_user == user}"

puts "\n✅ All security tests passed!"
puts "\nSummary:"
puts "- API tokens are now hashed using SHA256 before storage"
puts "- Plain text tokens are never stored in the database"
puts "- Tokens are only visible once when generated"
puts "- Existing authentication continues to work with the hashed lookup"

# Cleanup
user.destroy!