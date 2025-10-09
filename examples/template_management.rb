# frozen_string_literal: true

require 'whatsapp_cloud_api'

puts "=== Template Management Examples ==="

# Initialize client
client = KapsoClientRuby::Client.new(
  access_token: ENV['WHATSAPP_ACCESS_TOKEN']
)

business_account_id = ENV['BUSINESS_ACCOUNT_ID']

# Example 1: List Existing Templates
puts "\n--- List Existing Templates ---"

begin
  templates = client.templates.list(business_account_id: business_account_id)
  
  puts "Found #{templates.data.length} templates:"
  templates.data.each do |template|
    puts "- #{template.name} (#{template.language}) - Status: #{template.status}"
  end
  
  # Handle pagination if there are more results
  if templates.paging.after
    puts "\nMore templates available. Next cursor: #{templates.paging.after}"
  end
  
rescue KapsoClientRuby::Errors::GraphApiError => e
  puts "Error listing templates: #{e.message}"
end

# Example 2: Create Marketing Template
puts "\n--- Create Marketing Template ---"

begin
  # Build a marketing template with the helper method
  template_data = client.templates.build_marketing_template(
    name: 'ruby_sdk_promo',
    language: 'en_US',
    header: {
      type: 'HEADER',
      format: 'TEXT',
      text: 'Special Offer for {{1}}!'
    },
    body: 'Hi {{1}}, we have a special {{2}} discount just for you! Use code {{3}} to get {{4}} off your next purchase.',
    footer: 'This offer expires in 24 hours',
    buttons: [
      {
        type: 'URL',
        text: 'Shop Now',
        url: 'https://example.com/shop?code={{1}}'
      },
      {
        type: 'QUICK_REPLY',
        text: 'More Info'
      }
    ],
    body_example: {
      body_text: [['John', 'exclusive', 'SAVE20', '20%']]
    }
  )
  
  # Create the template
  response = client.templates.create(
    business_account_id: business_account_id,
    **template_data
  )
  
  puts "Marketing template created!"
  puts "Template ID: #{response.id}"
  puts "Status: #{response.status}"
  
rescue KapsoClientRuby::Errors::GraphApiError => e
  puts "Error creating marketing template: #{e.message}"
  
  if e.template_error?
    puts "Template-specific error - check template format and content"
  end
end

# Example 3: Create Authentication Template
puts "\n--- Create Authentication Template ---"

begin
  # Build authentication template using helper
  auth_template = client.templates.build_authentication_template(
    name: 'ruby_sdk_auth',
    language: 'en_US',
    ttl_seconds: 300, # 5 minutes
    code_expiration_minutes: 5,
    otp_type: 'COPY_CODE'
  )
  
  response = client.templates.create(
    business_account_id: business_account_id,
    **auth_template
  )
  
  puts "Authentication template created!"
  puts "Template ID: #{response.id}"
  puts "Status: #{response.status}"
  
rescue KapsoClientRuby::Errors::GraphApiError => e
  puts "Error creating auth template: #{e.message}"
end

# Example 4: Create Utility Template
puts "\n--- Create Utility Template ---"

begin
  utility_template = client.templates.build_utility_template(
    name: 'ruby_sdk_notification',
    language: 'en_US',
    header: {
      type: 'HEADER',
      format: 'TEXT',
      text: 'Order Update'
    },
    body: 'Your order #{{1}} has been {{2}}. Estimated delivery: {{3}}.',
    footer: 'Thank you for choosing our service',
    buttons: [
      {
        type: 'URL',
        text: 'Track Order',
        url: 'https://example.com/track/{{1}}'
      }
    ],
    body_example: {
      body_text: [['12345', 'shipped', 'Tomorrow 2-4 PM']]
    }
  )
  
  response = client.templates.create(
    business_account_id: business_account_id,
    **utility_template
  )
  
  puts "Utility template created!"
  puts "Template ID: #{response.id}"
  
rescue KapsoClientRuby::Errors::GraphApiError => e
  puts "Error creating utility template: #{e.message}"
end

# Example 5: Create Complex Template with All Components
puts "\n--- Create Complex Template ---"

begin
  components = [
    # Header with image
    {
      type: 'HEADER',
      format: 'IMAGE',
      example: {
        header_handle: ['https://example.com/header-image.jpg']
      }
    },
    # Body with variables
    {
      type: 'BODY',
      text: 'Hello {{1}}! Your {{2}} order totaling {{3}} is ready for pickup. ' \
            'Please bring your ID and order confirmation {{4}}.',
      example: {
        body_text: [['John Doe', 'premium', '$125.99', '#ORD12345']]
      }
    },
    # Footer
    {
      type: 'FOOTER',
      text: 'Reply STOP to unsubscribe'
    },
    # Multiple buttons
    {
      type: 'BUTTONS',
      buttons: [
        {
          type: 'URL',
          text: 'View Order',
          url: 'https://example.com/orders/{{1}}'
        },
        {
          type: 'PHONE_NUMBER',
          text: 'Call Store',
          phone_number: '+1234567890'
        },
        {
          type: 'QUICK_REPLY',
          text: 'Reschedule'
        }
      ]
    }
  ]
  
  response = client.templates.create(
    business_account_id: business_account_id,
    name: 'ruby_sdk_complex',
    language: 'en_US',
    category: 'UTILITY',
    components: components
  )
  
  puts "Complex template created!"
  puts "Template ID: #{response.id}"
  
rescue KapsoClientRuby::Errors::GraphApiError => e
  puts "Error creating complex template: #{e.message}"
end

# Example 6: Send Template Messages
puts "\n--- Send Template Messages ---"

begin
  # Send simple template without variables
  response1 = client.messages.send_template(
    phone_number_id: ENV['PHONE_NUMBER_ID'],
    to: '+1234567890',
    name: 'hello_world', # Meta's sample template
    language: 'en_US'
  )
  
  puts "Simple template sent: #{response1.messages.first.id}"
  
  # Send template with parameters
  response2 = client.messages.send_template(
    phone_number_id: ENV['PHONE_NUMBER_ID'],
    to: '+1234567890',
    name: 'ruby_sdk_promo', # Our created template
    language: 'en_US',
    components: [
      {
        type: 'header',
        parameters: [
          { type: 'text', text: 'John Doe' }
        ]
      },
      {
        type: 'body',
        parameters: [
          { type: 'text', text: 'John' },
          { type: 'text', text: 'exclusive' },
          { type: 'text', text: 'RUBY20' },
          { type: 'text', text: '20%' }
        ]
      },
      {
        type: 'button',
        sub_type: 'url',
        index: '0',
        parameters: [
          { type: 'text', text: 'RUBY20' }
        ]
      }
    ]
  )
  
  puts "Parameterized template sent: #{response2.messages.first.id}"
  
rescue KapsoClientRuby::Errors::GraphApiError => e
  puts "Error sending template: #{e.message}"
  
  case e.category
  when :template
    puts "Template error - check template name, language, and parameters"
  when :parameter
    puts "Parameter error - check component parameters format"
  end
end

# Example 7: Template Management Operations
puts "\n--- Template Management Operations ---"

begin
  # Get specific template details
  template_id = 'your_template_id' # Replace with actual template ID
  
  template = client.templates.get(
    business_account_id: business_account_id,
    template_id: template_id
  )
  
  puts "Template Details:"
  puts "Name: #{template.name}"
  puts "Status: #{template.status}"
  puts "Category: #{template.category}"
  puts "Quality Score: #{template.quality_score_category}"
  
  # Update template (if allowed)
  if template.status == 'REJECTED'
    puts "Attempting to update rejected template..."
    
    client.templates.update(
      business_account_id: business_account_id,
      template_id: template_id,
      category: 'UTILITY' # Change category if needed
    )
    
    puts "Template updated successfully"
  end
  
rescue KapsoClientRuby::Errors::GraphApiError => e
  puts "Template management error: #{e.message}"
end

# Example 8: Delete Templates
puts "\n--- Delete Templates ---"

begin
  # Delete by template ID
  client.templates.delete(
    business_account_id: business_account_id,
    template_id: 'template_id_to_delete'
  )
  
  puts "Template deleted by ID"
  
  # Delete by name and language
  client.templates.delete(
    business_account_id: business_account_id,
    name: 'ruby_sdk_test',
    language: 'en_US'
  )
  
  puts "Template deleted by name"
  
rescue KapsoClientRuby::Errors::GraphApiError => e
  puts "Delete error: #{e.message}"
  
  if e.http_status == 404
    puts "Template not found - may already be deleted"
  end
end

# Example 9: Template Validation and Best Practices
puts "\n--- Template Validation Examples ---"

# Good template example
def create_good_template(client, business_account_id)
  client.templates.create(
    business_account_id: business_account_id,
    name: 'good_template_example',
    language: 'en_US',
    category: 'UTILITY',
    components: [
      {
        type: 'BODY',
        text: 'Your appointment with {{1}} is confirmed for {{2}} at {{3}}.',
        example: {
          body_text: [['Dr. Smith', 'tomorrow', '2:00 PM']]
        }
      },
      {
        type: 'FOOTER',
        text: 'Reply CANCEL to cancel this appointment'
      }
    ]
  )
end

# Bad template example (this will likely be rejected)
def create_bad_template_example(client, business_account_id)
  begin
    client.templates.create(
      business_account_id: business_account_id,
      name: 'bad_template_example',
      language: 'en_US',
      category: 'MARKETING',
      components: [
        {
          type: 'BODY',
          text: 'URGENT!!! Buy now or MISS OUT!!! Limited time offer!!!'
          # No example provided, excessive caps, promotional language
        }
      ]
    )
  rescue KapsoClientRuby::Errors::GraphApiError => e
    puts "Bad template rejected (expected): #{e.message}"
  end
end

begin
  good_response = create_good_template(client, business_account_id)
  puts "Good template created: #{good_response.id}"
rescue => e
  puts "Error with good template: #{e.message}"
end

create_bad_template_example(client, business_account_id)

puts "\n=== Template Management Examples Completed ==="