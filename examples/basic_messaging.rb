# frozen_string_literal: true

require 'kapso-client-ruby'
require 'dotenv'

Dotenv.load

# Example 1: Basic Text Message
puts "=== Basic Text Message ==="

begin
  # Initialize client with access token (direct Meta API)
  client = KapsoClientRuby::Client.new(
    access_token: ENV['WHATSAPP_ACCESS_TOKEN']
  )
  
  # Send a simple text message
  response = client.messages.send_text(
    phone_number_id: ENV['PHONE_NUMBER_ID'],
    to: '+56912345678',
    body: 'Hello! This is a test message from Ruby SDK.'
  )
  
  puts "Message sent successfully!"
  puts "Message ID: #{response.messages.first.id}"
  puts "Contact: #{response.contacts.first.wa_id}"

rescue KapsoClientRuby::Errors::GraphApiError => e
  puts "API Error: #{e.message}"
  puts "Category: #{e.category}"
  puts "HTTP Status: #{e.http_status}"
  puts "Retry Action: #{e.retry_hint[:action]}"
  
  if e.rate_limit?
    puts "Rate limited! Retry after: #{e.retry_hint[:retry_after_ms]}ms"
  end
end

# Example 2: Media Message with Error Handling
puts "\n=== Media Message with Error Handling ==="

begin
  # Send image message
  response = client.messages.send_image(
    phone_number_id: ENV['PHONE_NUMBER_ID'],
    to: '+1234567890',
    image: {
      link: 'https://example.com/image.jpg',
      caption: 'Check out this image!'
    }
  )
  
  puts "Image message sent: #{response.messages.first.id}"

rescue KapsoClientRuby::Errors::GraphApiError => e
  case e.category
  when :media
    puts "Media error: #{e.details}"
    puts "Check your media file URL or format"
  when :parameter
    puts "Parameter error: #{e.message}"
    puts "Check your phone number and recipient format"
  when :throttling
    puts "Rate limited - waiting before retry"
    sleep(e.retry_hint[:retry_after_ms] / 1000.0) if e.retry_hint[:retry_after_ms]
  else
    puts "Other error: #{e.message}"
  end
end

# Example 3: Template Message
puts "\n=== Template Message ==="

begin
  response = client.messages.send_template(
    phone_number_id: ENV['PHONE_NUMBER_ID'],
    to: '+1234567890',
    name: 'welcome_template',
    language: 'en_US',
    components: [
      {
        type: 'body',
        parameters: [
          { type: 'text', text: 'John Doe' }
        ]
      }
    ]
  )
  
  puts "Template message sent: #{response.messages.first.id}"

rescue KapsoClientRuby::Errors::GraphApiError => e
  if e.template_error?
    puts "Template error: #{e.details}"
    puts "Check template name, language, and parameters"
  else
    puts "Error: #{e.message}"
  end
end

# Example 4: Interactive Buttons
puts "\n=== Interactive Buttons ==="

begin
  response = client.messages.send_interactive_buttons(
    phone_number_id: ENV['PHONE_NUMBER_ID'],
    to: '+1234567890',
    body_text: 'Please choose an option:',
    buttons: [
      {
        type: 'reply',
        reply: {
          id: 'option_1',
          title: 'Option 1'
        }
      },
      {
        type: 'reply',
        reply: {
          id: 'option_2',
          title: 'Option 2'
        }
      }
    ],
    header: {
      type: 'text',
      text: 'Choose Your Option'
    },
    footer: {
      text: 'Powered by Ruby SDK'
    }
  )
  
  puts "Interactive message sent: #{response.messages.first.id}"

rescue KapsoClientRuby::Errors::GraphApiError => e
  puts "Interactive message error: #{e.message}"
end

puts "\n=== Example completed ==="