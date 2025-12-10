# frozen_string_literal: true

# WhatsApp Enhanced Interactive Messages Examples
# Demonstrates updated button headers and list validations

require 'kapso-client-ruby'
require 'dotenv'

Dotenv.load

# Initialize client
client = KapsoClientRuby::Client.new(
  access_token: ENV['WHATSAPP_ACCESS_TOKEN']
)

phone_number_id = ENV['PHONE_NUMBER_ID']
recipient = '+1234567890'

puts "=== Enhanced Interactive Messages ===\n\n"

# 1. INTERACTIVE BUTTONS - Text Header

puts "1. Buttons with text header..."

begin
  response = client.messages.send_interactive_buttons(
    phone_number_id: phone_number_id,
    to: recipient,
    header: {
      type: 'text',
      text: 'Appointment Confirmation'
    },
    body_text: 'We have an appointment slot available for you tomorrow at 2:00 PM.',
    buttons: [
      { type: 'reply', reply: { id: 'confirm', title: 'Confirm' } },
      { type: 'reply', reply: { id: 'reschedule', title: 'Reschedule' } },
      { type: 'reply', reply: { id: 'cancel', title: 'Cancel' } }
    ],
    footer: 'Please respond within 24 hours'
  )
  
  puts "✓ Sent! ID: #{response.messages.first.id}\n\n"
rescue StandardError => e
  puts "✗ Error: #{e.message}\n\n"
end

# 2. INTERACTIVE BUTTONS - Image Header (NEW!)

puts "2. Buttons with image header (NEW FEATURE)..."

begin
  response = client.messages.send_interactive_buttons(
    phone_number_id: phone_number_id,
    to: recipient,
    header: {
      type: 'image',
      image: {
        link: 'https://example.com/product-image.jpg'
      }
    },
    body_text: 'Interested in this product? Choose an option below:',
    buttons: [
      { type: 'reply', reply: { id: 'buy_now', title: 'Buy Now' } },
      { type: 'reply', reply: { id: 'add_cart', title: 'Add to Cart' } },
      { type: 'reply', reply: { id: 'more_info', title: 'More Info' } }
    ],
    footer: '30-day money-back guarantee'
  )
  
  puts "✓ Sent! ID: #{response.messages.first.id}\n\n"
rescue StandardError => e
  puts "✗ Error: #{e.message}\n\n"
end

# 3. INTERACTIVE BUTTONS - Video Header (NEW!)

puts "3. Buttons with video header (NEW FEATURE)..."

begin
  response = client.messages.send_interactive_buttons(
    phone_number_id: phone_number_id,
    to: recipient,
    header: {
      type: 'video',
      video: {
        link: 'https://example.com/tutorial.mp4'
      }
    },
    body_text: 'Watch this quick tutorial. Was it helpful?',
    buttons: [
      { type: 'reply', reply: { id: 'yes', title: 'Yes, helpful' } },
      { type: 'reply', reply: { id: 'no', title: 'Not helpful' } }
    ]
  )
  
  puts "✓ Sent! ID: #{response.messages.first.id}\n\n"
rescue StandardError => e
  puts "✗ Error: #{e.message}\n\n"
end

# 4. INTERACTIVE BUTTONS - Document Header (NEW!)

puts "4. Buttons with document header (NEW FEATURE)..."

begin
  response = client.messages.send_interactive_buttons(
    phone_number_id: phone_number_id,
    to: recipient,
    header: {
      type: 'document',
      document: {
        link: 'https://example.com/invoice-12345.pdf',
        filename: 'invoice.pdf'
      }
    },
    body_text: 'Your invoice is ready. Please review and confirm:',
    buttons: [
      { type: 'reply', reply: { id: 'approve', title: 'Approve' } },
      { type: 'reply', reply: { id: 'question', title: 'Question' } }
    ],
    footer: 'Invoice #12345'
  )
  
  puts "✓ Sent! ID: #{response.messages.first.id}\n\n"
rescue StandardError => e
  puts "✗ Error: #{e.message}\n\n"
end

# 5. INTERACTIVE LIST - Extended Body Text

puts "5. List with extended body text (4096 chars)..."

long_body = "Welcome to our service menu! " + ("Here's what we offer. " * 100)
long_body = long_body[0...4000]  # Keep under 4096

begin
  response = client.messages.send_interactive_list(
    phone_number_id: phone_number_id,
    to: recipient,
    header: {
      type: 'text',
      text: 'Our Services'
    },
    body_text: long_body,
    button_text: 'View Services',
    sections: [
      {
        title: 'Popular Services',
        rows: [
          { id: 'service1', title: 'Web Design', description: 'Custom website design' },
          { id: 'service2', title: 'Mobile Apps', description: 'iOS and Android apps' },
          { id: 'service3', title: 'SEO', description: 'Search engine optimization' }
        ]
      }
    ],
    footer: 'Select a service for details'
  )
  
  puts "✓ Sent! ID: #{response.messages.first.id}\n\n"
rescue StandardError => e
  puts "✗ Error: #{e.message}\n\n"
end

# 6. INTERACTIVE LIST - Maximum Rows (10)

puts "6. List with maximum rows (10 total)..."

begin
  response = client.messages.send_interactive_list(
    phone_number_id: phone_number_id,
    to: recipient,
    body_text: 'Choose from our top 10 products:',
    button_text: 'View Products',
    sections: [
      {
        title: 'Electronics',
        rows: [
          { id: 'p1', title: 'Laptop', description: 'High-performance laptop' },
          { id: 'p2', title: 'Phone', description: 'Latest smartphone' },
          { id: 'p3', title: 'Tablet', description: 'Portable tablet' },
          { id: 'p4', title: 'Watch', description: 'Smart watch' },
          { id: 'p5', title: 'Earbuds', description: 'Wireless earbuds' }
        ]
      },
      {
        title: 'Accessories',
        rows: [
          { id: 'a1', title: 'Case', description: 'Protective case' },
          { id: 'a2', title: 'Charger', description: 'Fast charger' },
          { id: 'a3', title: 'Cable', description: 'USB-C cable' },
          { id: 'a4', title: 'Stand', description: 'Phone stand' },
          { id: 'a5', title: 'Adapter', description: 'Power adapter' }
        ]
      }
    ]
  )
  
  puts "✓ Sent with 10 rows! ID: #{response.messages.first.id}\n\n"
rescue StandardError => e
  puts "✗ Error: #{e.message}\n\n"
end

# 7. VALIDATION TESTS

puts "7. Testing enhanced validations...\n"

# Test button count validation (max 3)
puts "  Testing button count (max 3)..."
begin
  client.messages.send_interactive_buttons(
    phone_number_id: phone_number_id,
    to: recipient,
    body_text: 'Test',
    buttons: [
      { type: 'reply', reply: { id: '1', title: 'Button 1' } },
      { type: 'reply', reply: { id: '2', title: 'Button 2' } },
      { type: 'reply', reply: { id: '3', title: 'Button 3' } },
      { type: 'reply', reply: { id: '4', title: 'Button 4' } }  # Too many!
    ]
  )
  puts "  ✗ Validation failed\n"
rescue ArgumentError => e
  puts "  ✓ Validation passed: #{e.message}\n"
end

# Test list body text limit (4096)
puts "  Testing list body text (max 4096)..."
begin
  long_text = 'a' * 4097  # Exceeds limit
  client.messages.send_interactive_list(
    phone_number_id: phone_number_id,
    to: recipient,
    body_text: long_text,
    button_text: 'View',
    sections: [{ title: 'Test', rows: [{ id: '1', title: 'Item' }] }]
  )
  puts "  ✗ Validation failed\n"
rescue ArgumentError => e
  puts "  ✓ Validation passed: #{e.message}\n"
end

# Test list row count (max 10)
puts "  Testing list row count (max 10)..."
begin
  too_many_rows = (1..11).map { |i| { id: "item#{i}", title: "Item #{i}" } }
  client.messages.send_interactive_list(
    phone_number_id: phone_number_id,
    to: recipient,
    body_text: 'Select',
    button_text: 'View',
    sections: [{ title: 'Items', rows: too_many_rows }]
  )
  puts "  ✗ Validation failed\n"
rescue ArgumentError => e
  puts "  ✓ Validation passed: #{e.message}\n"
end

# Test list header type (text only)
puts "  Testing list header type (text only)..."
begin
  client.messages.send_interactive_list(
    phone_number_id: phone_number_id,
    to: recipient,
    header: {
      type: 'image',  # Lists only support text headers!
      image: { link: 'https://example.com/image.jpg' }
    },
    body_text: 'Test',
    button_text: 'View',
    sections: [{ title: 'Test', rows: [{ id: '1', title: 'Item' }] }]
  )
  puts "  ✗ Validation failed\n"
rescue ArgumentError => e
  puts "  ✓ Validation passed: #{e.message}\n"
end

# Test button header with invalid media
puts "  Testing button header validation..."
begin
  client.messages.send_interactive_buttons(
    phone_number_id: phone_number_id,
    to: recipient,
    header: {
      type: 'image'
      # Missing image field!
    },
    body_text: 'Test',
    buttons: [{ type: 'reply', reply: { id: '1', title: 'OK' } }]
  )
  puts "  ✗ Validation failed\n"
rescue ArgumentError => e
  puts "  ✓ Validation passed: #{e.message}\n"
end

puts "\n=== All enhanced features demonstrated! ===\n"

# USE CASES

puts "\n=== Real-World Use Cases ===\n"

# E-commerce: Product selection with image
def product_quick_buy(client, phone_number_id, customer_phone)
  client.messages.send_interactive_buttons(
    phone_number_id: phone_number_id,
    to: customer_phone,
    header: {
      type: 'image',
      image: { link: 'https://shop.example.com/featured-product.jpg' }
    },
    body_text: '🔥 Flash Sale! This item is 50% off for the next 2 hours.',
    buttons: [
      { type: 'reply', reply: { id: 'buy', title: 'Buy Now' } },
      { type: 'reply', reply: { id: 'cart', title: 'Add to Cart' } },
      { type: 'reply', reply: { id: 'notify', title: 'Notify Later' } }
    ],
    footer: 'Limited stock available'
  )
end

# Customer Support: Video tutorial  with feedback
def send_tutorial_with_feedback(client, phone_number_id, customer_phone)
  client.messages.send_interactive_buttons(
    phone_number_id: phone_number_id,
    to: customer_phone,
    header: {
      type: 'video',
      video: { link: 'https://support.example.com/tutorials/setup.mp4' }
    },
    body_text: '📺 Here\'s a quick video showing how to set up your device. Did this help?',
    buttons: [
      { type: 'reply', reply: { id: 'solved', title: 'Problem Solved' } },
      { type: 'reply', reply: { id: 'more_help', title: 'Need More Help' } }
    ],
    footer: 'Support Team'
  )
end

# Document approval workflow
def document_approval(client, phone_number_id, manager_phone)
  client.messages.send_interactive_buttons(
    phone_number_id: phone_number_id,
    to: manager_phone,
    header: {
      type: 'document',
      document: {
        link: 'https://docs.example.com/contracts/2024-Q1.pdf',
        filename: 'Q1-2024-Contract.pdf'
      }
    },
    body_text: '📄 Contract requires your approval. Please review the attached document.',
    buttons: [
      { type: 'reply', reply: { id: 'approve', title: 'Approve' } },
      { type: 'reply', reply: { id: 'reject', title: 'Reject' } },
      { type: 'reply', reply: { id: 'clarify', title: 'Ask Question' } }
    ],
    footer: 'Deadline: Friday 5 PM'
  )
end

# Comprehensive service menu (using max rows)
def comprehensive_service_menu(client, phone_number_id, customer_phone)
  client.messages.send_interactive_list(
    phone_number_id: phone_number_id,
    to: customer_phone,
    header: {
      type: 'text',
      text: 'Complete Service Catalog'
    },
    body_text: 'Browse our full catalog of services. We offer professional solutions across multiple categories to meet all your business needs.',
    button_text: 'Browse Services',
    sections: [
      {
        title: 'Design Services',
        rows: [
          { id: 'web_design', title: 'Web Design', description: 'Custom website design' },
          { id: 'brand_design', title: 'Brand Design', description: 'Logo and branding' },
          { id: 'ui_design', title: 'UI/UX Design', description: 'User interface design' }
        ]
      },
      {
        title: 'Development Services',
        rows: [
          { id: 'web_dev', title: 'Web Development', description: 'Full-stack development' },
          { id: 'mobile_dev', title: 'Mobile Apps', description: 'iOS & Android apps' },
          { id: 'api_dev', title: 'API Development', description: 'Backend APIs' }
        ]
      },
      {
        title: 'Marketing Services',
        rows: [
          { id: 'seo', title: 'SEO', description: 'Search optimization' },
          { id: 'social', title: 'Social Media', description: 'Social media marketing' },
          { id: 'email', title: 'Email Marketing', description: 'Email campaigns' },
          { id: 'content', title: 'Content Marketing', description: 'Content creation' }
        ]
      }
    ],
    footer: 'Get a free consultation'
  )
end