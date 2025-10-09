# frozen_string_literal: true

namespace :kapso do
  desc 'Test Kapso configuration and send a test message'
  task test: :environment do
    puts "🔧 Testing Kapso configuration..."
    
    # Check configuration
    client = KapsoClientRuby::Client.new
    puts "✅ Kapso client initialized"
    puts "📱 Phone Number ID: #{client.phone_number_id}"
    puts "🏢 Business Account ID: #{client.business_account_id}"
    
    # Test API connection
    begin
      templates = client.templates.list(limit: 1)
      puts "✅ API connection successful"
      puts "📋 Found #{templates.dig('data')&.length || 0} templates"
    rescue => e
      puts "❌ API connection failed: #{e.message}"
      exit 1
    end
    
    # Send test message if phone number is provided
    test_number = ENV['KAPSO_TEST_PHONE_NUMBER']
    if test_number
      puts "\n📤 Sending test message to #{test_number}..."
      service = KapsoMessageService.new
      service.send_test_message
    else
      puts "\n💡 Set KAPSO_TEST_PHONE_NUMBER to test messaging"
    end
  end

  desc 'List available WhatsApp message templates'
  task templates: :environment do
    puts "📋 Fetching WhatsApp templates..."
    
    service = KapsoMessageService.new
    templates_response = service.list_templates
    
    if templates_response && templates_response['data']
      templates = templates_response['data']
      puts "Found #{templates.length} templates:\n\n"
      
      templates.each do |template|
        puts "📄 #{template['name']}"
        puts "   Status: #{template['status']}"
        puts "   Language: #{template['language']}"
        puts "   Category: #{template['category']}"
        puts "   Created: #{Time.at(template['created_time']).to_s}" if template['created_time']
        puts ""
      end
    else
      puts "❌ Failed to fetch templates or no templates found"
    end
  end

  desc 'Check message status'
  task :message_status, [:message_id] => :environment do |task, args|
    message_id = args[:message_id]
    
    unless message_id
      puts "❌ Please provide a message ID: rake kapso:message_status[message_id]"
      exit 1
    end
    
    puts "🔍 Checking status for message: #{message_id}"
    
    service = KapsoMessageService.new
    status = service.get_message_status(message_id)
    
    if status
      puts "📊 Message Status:"
      puts "   ID: #{status['id']}"
      puts "   Status: #{status['status']}"
      puts "   Timestamp: #{Time.at(status['timestamp']).to_s}" if status['timestamp']
      puts "   Recipient: #{status['recipient_id']}" if status['recipient_id']
      
      if status['errors']
        puts "   Errors: #{status['errors']}"
      end
    else
      puts "❌ Failed to get message status"
    end
  end

  desc 'Validate webhook configuration'
  task validate_webhook: :environment do
    puts "🔗 Validating webhook configuration..."
    
    # Check required environment variables
    required_vars = %w[KAPSO_WEBHOOK_VERIFY_TOKEN]
    optional_vars = %w[KAPSO_WEBHOOK_SECRET]
    
    required_vars.each do |var|
      if ENV[var].present?
        puts "✅ #{var} is set"
      else
        puts "❌ #{var} is not set (required)"
      end
    end
    
    optional_vars.each do |var|
      if ENV[var].present?
        puts "✅ #{var} is set (recommended for security)"
      else
        puts "⚠️  #{var} is not set (optional but recommended)"
      end
    end
    
    # Check if routes are properly configured
    begin
      webhook_path = Rails.application.routes.url_helpers.kapso_webhooks_path rescue nil
      if webhook_path
        puts "✅ Webhook routes are configured"
        puts "   Webhook URL: #{Rails.application.config.force_ssl ? 'https' : 'http'}://yourapp.com#{webhook_path}"
      else
        puts "⚠️  Webhook routes may not be configured. Make sure to add:"
        puts "     post '/webhooks/kapso', to: 'kapso_webhooks#create'"
        puts "     get '/webhooks/kapso', to: 'kapso_webhooks#verify'"
      end
    rescue => e
      puts "⚠️  Could not check webhook routes: #{e.message}"
    end
  end

  desc 'Generate sample environment file'
  task :sample_env do
    puts "📝 Generating .env.kapso.sample file..."
    
    env_content = <<~ENV
      # Kapso API Configuration
      # Copy this to your .env file and fill in your actual values
      
      # Required: Your Kapso API access token
      KAPSO_API_KEY=your_api_key_here
      
      # Required: Your WhatsApp Business phone number ID  
      KAPSO_PHONE_NUMBER_ID=your_phone_number_id_here
      
      # Required: Your WhatsApp Business account ID
      KAPSO_BUSINESS_ACCOUNT_ID=your_business_account_id_here
      
      # Optional: API configuration
      KAPSO_API_HOST=https://graph.facebook.com
      KAPSO_API_VERSION=v18.0
      KAPSO_TIMEOUT=30
      
      # Optional: Debug and retry settings
      KAPSO_DEBUG=false
      KAPSO_RETRY_ON_FAILURE=true
      KAPSO_MAX_RETRIES=3
      
      # Webhook configuration
      KAPSO_WEBHOOK_VERIFY_TOKEN=your_webhook_verify_token_here
      KAPSO_WEBHOOK_SECRET=your_webhook_secret_here
      
      # Testing
      KAPSO_TEST_PHONE_NUMBER=+1234567890
    ENV
    
    File.write('.env.kapso.sample', env_content)
    puts "✅ Created .env.kapso.sample"
    puts "💡 Copy this to .env and update with your actual credentials"
  end
end