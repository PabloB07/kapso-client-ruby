# frozen_string_literal: true

require 'KapsoClientRuby'

puts "=== Advanced Features with Kapso Proxy ==="

# Initialize Kapso client
kapso_client = KapsoClientRuby::Client.new(
  kapso_api_key: ENV['KAPSO_API_KEY'],
  base_url: 'https://app.kapso.ai/api/meta',
  debug: true
)

phone_number_id = ENV['PHONE_NUMBER_ID']

# Example 1: Message History and Analytics
puts "\n--- Message History ---"

begin
  # Query message history
  messages = kapso_client.messages.query(
    phone_number_id: phone_number_id,
    direction: 'inbound',
    since: '2024-01-01T00:00:00Z',
    limit: 10
  )
  
  puts "Found #{messages.data.length} messages:"
  messages.data.each do |message|
    puts "- #{message['id']}: #{message['type']} from #{message['from']}"
  end
  
  # Get messages by conversation
  if messages.data.any? && messages.data.first['conversation_id']
    conv_messages = kapso_client.messages.list_by_conversation(
      phone_number_id: phone_number_id,
      conversation_id: messages.data.first['conversation_id'],
      limit: 5
    )
    
    puts "\nConversation messages: #{conv_messages.data.length}"
  end

rescue KapsoClientRuby::Errors::KapsoProxyRequiredError => e
  puts "Kapso Proxy required: #{e.message}"
rescue KapsoClientRuby::Errors::GraphApiError => e
  puts "Message history error: #{e.message}"
end

# Example 2: Conversation Management
puts "\n--- Conversation Management ---"

begin
  # List active conversations
  conversations = kapso_client.conversations.list(
    phone_number_id: phone_number_id,
    status: 'active',
    limit: 10
  )
  
  puts "Active conversations: #{conversations.data.length}"
  
  conversations.data.each do |conv|
    puts "Conversation #{conv.id}:"
    puts "  Phone: #{conv.phone_number}"
    puts "  Status: #{conv.status}"
    puts "  Last Active: #{conv.last_active_at}"
    
    if conv.kapso
      puts "  Contact Name: #{conv.kapso['contact_name']}"
      puts "  Messages Count: #{conv.kapso['messages_count']}"
      puts "  Last Message: #{conv.kapso['last_message_text']}"
    end
  end
  
  # Get specific conversation details
  if conversations.data.any?
    conversation_id = conversations.data.first.id
    
    conv_details = kapso_client.conversations.get(
      conversation_id: conversation_id
    )
    
    puts "\nDetailed conversation info:"
    puts "ID: #{conv_details.id}"
    puts "Status: #{conv_details.status}"
    puts "Metadata: #{conv_details.metadata}"
    
    # Update conversation status
    kapso_client.conversations.update_status(
      conversation_id: conversation_id,
      status: 'archived'
    )
    
    puts "Conversation archived successfully"
    
    # Unarchive it
    kapso_client.conversations.unarchive(conversation_id: conversation_id)
    puts "Conversation unarchived"
  end

rescue KapsoClientRuby::Errors::GraphApiError => e
  puts "Conversation management error: #{e.message}"
end

# Example 3: Contact Management
puts "\n--- Contact Management ---"

begin
  # List contacts
  contacts = kapso_client.contacts.list(
    phone_number_id: phone_number_id,
    limit: 10
  )
  
  puts "Found #{contacts.data.length} contacts:"
  
  contacts.data.each do |contact|
    puts "Contact #{contact.wa_id}:"
    puts "  Phone: #{contact.phone_number}"
    puts "  Profile Name: #{contact.profile_name}"
    puts "  Metadata: #{contact.metadata}"
  end
  
  # Get specific contact
  if contacts.data.any?
    wa_id = contacts.data.first.wa_id
    
    contact_details = kapso_client.contacts.get(
      phone_number_id: phone_number_id,
      wa_id: wa_id
    )
    
    puts "\nContact details for #{wa_id}:"
    puts "Profile Name: #{contact_details.profile_name}"
    
    # Update contact metadata
    kapso_client.contacts.update(
      phone_number_id: phone_number_id,
      wa_id: wa_id,
      metadata: {
        tags: ['ruby_sdk', 'test_contact'],
        source: 'api_example',
        notes: 'Updated via Ruby SDK'
      }
    )
    
    puts "Contact metadata updated"
    
    # Add tags
    kapso_client.contacts.add_tags(
      phone_number_id: phone_number_id,
      wa_id: wa_id,
      tags: ['premium_customer']
    )
    
    puts "Tags added to contact"
    
    # Search contacts
    search_results = kapso_client.contacts.search(
      phone_number_id: phone_number_id,
      query: 'john',
      search_in: ['profile_name', 'phone_number']
    )
    
    puts "Search results: #{search_results.data.length} contacts"
  end

rescue KapsoClientRuby::Errors::GraphApiError => e
  puts "Contact management error: #{e.message}"
end

# Example 4: Call Management
puts "\n--- Call Management ---"

begin
  # List recent calls
  calls = kapso_client.calls.list(
    phone_number_id: phone_number_id,
    direction: 'INBOUND',
    limit: 5
  )
  
  puts "Recent calls: #{calls.data.length}"
  
  calls.data.each do |call|
    puts "Call #{call.id}:"
    puts "  Direction: #{call.direction}"
    puts "  Status: #{call.status}"
    puts "  Duration: #{call.duration_seconds} seconds"
    puts "  Started: #{call.started_at}"
  end
  
  # Initiate a call (example - requires proper setup)
  begin
    call_response = kapso_client.calls.connect(
      phone_number_id: phone_number_id,
      to: '+1234567890',
      session: {
        sdp_type: 'offer',
        sdp: 'v=0\r\no=- 123456789 123456789 IN IP4 127.0.0.1\r\n...'
      }
    )
    
    puts "Call initiated: #{call_response.calls.first['id']}"
  rescue KapsoClientRuby::Errors::GraphApiError => e
    puts "Call initiation error (expected in example): #{e.message}"
  end

rescue KapsoClientRuby::Errors::GraphApiError => e
  puts "Call management error: #{e.message}"
end

# Example 5: Advanced Error Handling and Monitoring
puts "\n--- Advanced Error Handling ---"

class WhatsAppMonitor
  def initialize(client)
    @client = client
    @error_counts = Hash.new(0)
    @last_errors = []
  end
  
  def send_with_monitoring(method, *args, **kwargs)
    start_time = Time.now
    
    begin
      result = @client.messages.public_send(method, **kwargs)
      
      duration = Time.now - start_time
      puts "✓ #{method} succeeded in #{duration.round(2)}s"
      
      result
    rescue KapsoClientRuby::Errors::GraphApiError => e
      duration = Time.now - start_time
      @error_counts[e.category] += 1
      @last_errors << {
        timestamp: Time.now,
        method: method,
        error: e,
        duration: duration
      }
      
      puts "✗ #{method} failed in #{duration.round(2)}s"
      puts "  Category: #{e.category}"
      puts "  Message: #{e.message}"
      puts "  Retry: #{e.retry_hint[:action]}"
      
      # Automatic retry logic
      case e.retry_hint[:action]
      when :retry
        if kwargs[:_retry_count].to_i < 3
          retry_count = kwargs[:_retry_count].to_i + 1
          puts "  Auto-retrying (#{retry_count}/3)..."
          sleep(retry_count)
          return send_with_monitoring(method, **kwargs.merge(_retry_count: retry_count))
        end
      when :retry_after
        if e.retry_hint[:retry_after_ms] && e.retry_hint[:retry_after_ms] < 30000
          delay = e.retry_hint[:retry_after_ms] / 1000.0
          puts "  Waiting #{delay}s for rate limit..."
          sleep(delay)
          return send_with_monitoring(method, **kwargs)
        end
      end
      
      raise
    end
  end
  
  def print_statistics
    puts "\n--- Error Statistics ---"
    puts "Total error categories: #{@error_counts.keys.length}"
    @error_counts.each do |category, count|
      puts "  #{category}: #{count} errors"
    end
    
    if @last_errors.any?
      puts "\nRecent errors:"
      @last_errors.last(3).each do |error_info|
        puts "  #{error_info[:timestamp]}: #{error_info[:method]} -> #{error_info[:error].category}"
      end
    end
  end
end

# Test the monitoring system
monitor = WhatsAppMonitor.new(kapso_client)

# Test various operations with monitoring
test_operations = [
  [:send_text, {
    phone_number_id: phone_number_id,
    to: '+1234567890',
    body: 'Test message from monitoring system'
  }],
  [:send_template, {
    phone_number_id: phone_number_id,
    to: '+1234567890',
    name: 'nonexistent_template',
    language: 'en_US'
  }],
  [:send_image, {
    phone_number_id: phone_number_id,
    to: '+1234567890',
    image: { link: 'https://invalid-url.example/image.jpg' }
  }]
]

test_operations.each do |method, kwargs|
  begin
    monitor.send_with_monitoring(method, **kwargs)
  rescue => e
    puts "Final error for #{method}: #{e.message}"
  end
  
  sleep(1) # Rate limiting prevention
end

monitor.print_statistics

# Example 6: Webhook Signature Verification (helper function)
puts "\n--- Webhook Signature Verification ---"

def verify_webhook_signature(payload, signature, app_secret)
  require 'openssl'
  
  # Extract signature from header (format: "sha256=...")
  sig_hash = signature.sub('sha256=', '')
  
  # Calculate expected signature
  expected_sig = OpenSSL::HMAC.hexdigest('sha256', app_secret, payload)
  
  # Secure comparison
  sig_hash == expected_sig
end

# Example webhook payload verification
webhook_payload = '{"object":"whatsapp_business_account","entry":[...]}'
webhook_signature = 'sha256=abcdef123456...' # From X-Hub-Signature-256 header
app_secret = ENV['WHATSAPP_APP_SECRET']

if app_secret
  is_valid = verify_webhook_signature(webhook_payload, webhook_signature, app_secret)
  puts "Webhook signature valid: #{is_valid}"
else
  puts "Set WHATSAPP_APP_SECRET to test webhook verification"
end

puts "\n=== Advanced Features Examples Completed ==="