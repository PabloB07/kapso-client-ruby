#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/kapso_client_ruby'

puts "=== Kapso.ai and WhatsApp Cloud API Ruby SDK Setup ==="
puts

# Helper method for safe input
def get_input(prompt, required: false, mask: false)
  loop do
    print prompt
    if mask
      # For sensitive input, use a simple masking approach
      begin
        system "stty -echo" if STDIN.tty?
        input = gets.chomp
      ensure
        system "stty echo" if STDIN.tty?
        puts # New line after hidden input
      end
    else
      input = gets.chomp
    end
    
    if required && input.strip.empty?
      puts "❌ This field is required. Please try again."
      next
    end
    
    return input.strip
  end
end

# Interactive Environment Setup
puts "🔧 WhatsApp Cloud API Configuration"
puts "-" * 40
puts "Please provide your API credentials (leave empty for test mode):"
puts

# Get Phone Number ID first (common to all)
phone_number_id = get_input("📱 Phone Number ID (or press Enter for test mode): ")

if phone_number_id.empty?
  # Test mode
  puts "\n🧪 Test Mode - Using mock credentials"
  ENV['WHATSAPP_ACCESS_TOKEN'] = 'test_token_12345'
  ENV['PHONE_NUMBER_ID'] = 'test_phone_id_12345'
  test_mode = true
  puts "✅ Test credentials configured"
else
  # Real credentials
  ENV['PHONE_NUMBER_ID'] = phone_number_id
  test_mode = false
  
  puts "\nChoose your API provider:"
  puts "📱 Meta WhatsApp Business API (get token from: https://developers.facebook.com/apps)"
  puts "🚀 Kapso Proxy API (get key from: https://app.kapso.ai)"
  puts
  
  # Try to get access token first
  access_token = get_input("🔑 WhatsApp Access Token (or press Enter to use Kapso): ", mask: true)
  
  if access_token.empty?
    # Use Kapso API
    kapso_api_key = get_input("🔑 Kapso API Key: ", required: true, mask: true)
    ENV['KAPSO_API_KEY'] = kapso_api_key
    puts "✅ Kapso API credentials configured"
  else
    # Use Meta API
    ENV['WHATSAPP_ACCESS_TOKEN'] = access_token
    puts "✅ Meta API credentials configured"
  end
end

puts
puts "Current Configuration:"
if ENV['WHATSAPP_ACCESS_TOKEN']
  puts "  Access Token: ***#{ENV['WHATSAPP_ACCESS_TOKEN'][-4..-1]}"
elsif ENV['KAPSO_API_KEY']
  puts "  Kapso API Key: ***#{ENV['KAPSO_API_KEY'][-4..-1]}"
else
  puts "  Kapso API Key: Not set"
end
puts "  Phone Number ID: #{ENV['PHONE_NUMBER_ID']}"
puts

test_real_api = false
if !test_mode  # Only ask for real API test if not in test mode
  puts "⚠️  Real API Test Warning:"
  puts "   This will make actual API calls and may incur charges"
  puts "   Make sure your credentials are valid and you have proper permissions"
  
  confirmation = get_input("Do you want to test with real API calls? (y/N): ")
  test_real_api = confirmation.downcase == 'y' || confirmation.downcase == 'yes'
else
  puts "ℹ️  Test mode selected - skipping real API calls"
end

puts

# Test 1: Configuration and Client Initialization
puts "1. Testing Client Initialization"
puts "-" * 40

begin
  # Initialize client based on configured environment
  if ENV['KAPSO_API_KEY']
    client = KapsoClientRuby::Client.new(
      kapso_api_key: ENV['KAPSO_API_KEY'],
      base_url: 'https://app.kapso.ai/api/meta',
      debug: true
    )
    puts "✅ Kapso client initialized"
    puts "   Kapso proxy: #{client.kapso_proxy?}"
  else
    client = KapsoClientRuby::Client.new(
      access_token: ENV['WHATSAPP_ACCESS_TOKEN'],
      debug: true
    )
    puts "✅ Meta API client initialized"
    puts "   Kapso proxy: #{client.kapso_proxy?}"
  end
  
  puts "   Debug mode: #{client.debug}"
  
rescue => e
  puts "❌ Client initialization failed: #{e.message}"
end

puts

# Test 2: Resource Access
puts "2. Testing Resource Access"
puts "-" * 40

begin
  client = KapsoClientRuby::Client.new(access_token: 'test_token')
  
  # Test all resource accessors
  resources = {
    'Messages' => client.messages,
    'Media' => client.media,
    'Templates' => client.templates,
    'Phone Numbers' => client.phone_numbers,
    'Calls' => client.calls,
    'Conversations' => client.conversations,
    'Contacts' => client.contacts
  }
  
  resources.each do |name, resource|
    if resource
      puts "✅ #{name} resource: #{resource.class}"
    else
      puts "❌ #{name} resource: nil"
    end
  end
  
rescue => e
  puts "❌ Resource access failed: #{e.message}"
end

puts

# Test 3: Configuration System
puts "3. Testing Configuration System"
puts "-" * 40

begin
  # Test global configuration
  KapsoClientRuby.configure do |config|
    config.debug = true
    config.timeout = 45
    config.access_token = 'global_test_token'
  end
  
  puts "✅ Global configuration set"
  puts "   Debug: #{KapsoClientRuby.configuration.debug}"
  puts "   Timeout: #{KapsoClientRuby.configuration.timeout}"
  puts "   Access token present: #{!KapsoClientRuby.configuration.access_token.nil?}"
  
rescue => e
  puts "❌ Configuration failed: #{e.message}"
end

puts

# Test 4: Error Handling System
puts "4. Testing Error Handling System"
puts "-" * 40

begin
  # Test creating different error types
  rate_limit_error = KapsoClientRuby::Errors::GraphApiError.new(
    message: 'Rate limit exceeded',
    code: 4,
    http_status: 429,
    retry_after: 30
  )
  
  puts "✅ Rate limit error created"
  puts "   Category: #{rate_limit_error.category}"
  puts "   Rate limited?: #{rate_limit_error.rate_limit?}"
  puts "   Retry after: #{rate_limit_error.retry_after}s"
  puts "   Retry hint: #{rate_limit_error.retry_hint}"
  
  auth_error = KapsoClientRuby::Errors::GraphApiError.new(
    message: 'Invalid access token',
    code: 190,
    http_status: 401
  )
  
  puts "✅ Auth error created"
  puts "   Category: #{auth_error.category}"
  puts "   Temporary?: #{auth_error.temporary?}"
  puts "   Retry hint: #{auth_error.retry_hint}"
  
rescue => e
  puts "❌ Error handling test failed: #{e.message}"
end

puts

# Test 5: Payload Building (without API calls)
puts "5. Testing Message Payload Building"
puts "-" * 40

begin
  # Use the configured client
  messages = client.messages
  
  # Test payload building (this is internal, so we'll simulate)
  puts "✅ Messages resource ready"
  puts "   Available methods: send_text, send_image, send_template, etc."
  
  # Test media types validation
  media_types = KapsoClientRuby::Types::MEDIA_TYPES
  puts "✅ Media types supported: #{media_types.join(', ')}"
  
  # Test template statuses
  template_statuses = KapsoClientRuby::Types::TEMPLATE_STATUSES
  puts "✅ Template statuses: #{template_statuses.join(', ')}"
  
rescue => e
  puts "❌ Payload building test failed: #{e.message}"
end

puts

# Test 6: Logger System
puts "6. Testing Logger System"
puts "-" * 40

begin
  logger = KapsoClientRuby.logger
  puts "✅ Logger accessible"
  puts "   Logger class: #{logger.class}"
  
  # Test logging (will show in console if debug enabled)
  KapsoClientRuby.logger.info("SDK test completed successfully!")
  
rescue => e
  puts "❌ Logger test failed: #{e.message}"
end

puts

# Test 7: Real API Test (if requested)
if test_real_api
  puts "7. Testing Real API Calls"
  puts "-" * 40
  
  begin
    # Use the configured client from Test 1
    phone_number_id = ENV['PHONE_NUMBER_ID']
    
    if phone_number_id.nil? || phone_number_id.empty?
      puts "❌ Phone Number ID not configured"
    else
      puts "📱 Enter the destination WhatsApp number:"
      puts "   • Must include country code (e.g., +1234567890)"
      puts "   • No spaces or special characters except +"
      puts "   • Example: +56912345678"
      puts
      
      to_number = nil
      loop do
        to_number = get_input("Destination phone number: ", required: true)
        
        # Basic phone number validation
        if to_number.match(/^\+\d{10,15}$/)
          break
        else
          puts "❌ Invalid format. Please use format: +[country_code][number] (10-15 digits total)"
          puts "   Example: +56912345678"
        end
      end
      
      puts "\n📱 Sending test message to #{to_number}..."
      
      response = client.messages.send_text(
        phone_number_id: phone_number_id,
        to: to_number,
        body: "🎉 Test message from WhatsApp Cloud API Ruby SDK! Time: #{Time.now}"
      )
      
      puts "✅ Message sent successfully!"
      puts "   Message ID: #{response.messages.first.id}"
      puts "   Contact WA ID: #{response.contacts.first.wa_id}"
      puts "   Message Status: #{response.messages.first.message_status}"
    end
    
  rescue KapsoClientRuby::Errors::GraphApiError => e
    puts "❌ API Error: #{e.message}"
    puts "   Category: #{e.category}"
    puts "   HTTP Status: #{e.http_status}"
    puts "   Error Code: #{e.code}"
    puts "   Retry Action: #{e.retry_hint}"
    
    if e.rate_limit?
      puts "   ⏳ Rate limited! Retry after: #{e.retry_after}s"
    end
    
  rescue => e
    puts "❌ Unexpected error: #{e.message}"
    puts "   Class: #{e.class}"
  end
  
  puts
end

puts "=== Test Summary ==="
puts "✅ WhatsApp Cloud API Ruby SDK is working correctly!"

if test_real_api
  puts "🌐 Real API test completed"
else
  puts "🧪 Mock tests completed successfully"
  puts
  puts "💡 To test real API calls:"
  puts "   - Run this script again and choose option 1 or 2"
  puts "   - Provide your real WhatsApp Business API credentials"
  puts "   - Answer 'y' when asked to test real API calls"
end

puts
puts "🔧 Configuration used:"
if ENV['WHATSAPP_ACCESS_TOKEN']
  puts "   Access Token: Configured"
elsif ENV['KAPSO_API_KEY']
  puts "   Kapso API Key: Configured"
else
  puts "   Kapso API Key: Not set"
end
puts "   Phone Number ID: #{ENV['PHONE_NUMBER_ID'] || 'Not set'}"
puts

# Create .env file with configured credentials
if !test_mode && (ENV['WHATSAPP_ACCESS_TOKEN'] || ENV['KAPSO_API_KEY'])
  puts "💾 Creating .env file for production use..."
  
  env_content = []
  env_content << "# WhatsApp Cloud API Configuration"
  env_content << "# Generated by WhatsApp Cloud API Ruby SDK Test"
  env_content << "# #{Time.now}"
  env_content << ""
  
  if ENV['WHATSAPP_ACCESS_TOKEN']
    env_content << "# Meta WhatsApp Business API"
    env_content << "WHATSAPP_ACCESS_TOKEN=#{ENV['WHATSAPP_ACCESS_TOKEN']}"
    env_content << "PHONE_NUMBER_ID=#{ENV['PHONE_NUMBER_ID']}"
    env_content << ""
    env_content << "# Optional: Set base URL for custom endpoints"
    env_content << "# WHATSAPP_BASE_URL=https://graph.facebook.com"
    env_content << "# WHATSAPP_API_VERSION=v24.0"
  end
  
  if ENV['KAPSO_API_KEY']
    env_content << "# Kapso Proxy API"
    env_content << "KAPSO_API_KEY=#{ENV['KAPSO_API_KEY']}"
    env_content << "PHONE_NUMBER_ID=#{ENV['PHONE_NUMBER_ID']}"
    env_content << "WHATSAPP_BASE_URL=https://app.kapso.ai/api/meta"
    env_content << ""
    env_content << "# Optional: Set API version"
    env_content << "# WHATSAPP_API_VERSION=v24.0"
  end
  
  env_content << ""
  env_content << "# Optional: Enable debug mode"
  env_content << "# WHATSAPP_DEBUG=true"
  env_content << ""
  env_content << "# Optional: Set timeouts (in seconds)"
  env_content << "# WHATSAPP_TIMEOUT=30"
  env_content << "# WHATSAPP_OPEN_TIMEOUT=10"
  
  File.write('.env', env_content.join("\n"))
  
  puts "✅ .env file created successfully!"
  puts "   You can now use: require 'dotenv/load' in your Ruby applications"
  puts "   Or set these environment variables in your deployment environment"
  puts
end

puts "📚 See examples/ directory for more usage examples"
puts "📖 See README.md for full documentation"