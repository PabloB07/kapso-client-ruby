# frozen_string_literal: true

# WhatsApp Interactive Messages Examples
# Demonstrates CTA URL and Catalog messages

require 'kapso-client-ruby'
require 'dotenv'

Dotenv.load

# Initialize client
client = KapsoClientRuby::Client.new(
  access_token: ENV['WHATSAPP_ACCESS_TOKEN']
)

phone_number_id = ENV['PHONE_NUMBER_ID']
recipient = '+1234567890'

puts "=== Interactive Messages Examples ===\n\n"

# 1. INTERACTIVE CTA URL - Text Header

puts "1. Sending CTA URL message with text header..."

begin
  response = client.messages.send_interactive_cta_url(
    phone_number_id: phone_number_id,
    to: recipient,
    header: {
      type: 'text',
      text: 'Special Offer'
    },
    body_text: 'Get 25% off your first purchase! Click below to shop now.',
    display_text: 'Shop Now',
    url: 'https://shop.example.com?utm_source=whatsapp',
    footer_text: 'Limited time offer'
  )
  
  puts "✓ Message sent! ID: #{response.messages.first.id}\n\n"
rescue StandardError => e
  puts "✗ Error: #{e.message}\n\n"
end

# 2. INTERACTIVE CTA URL - Image Header

puts "2. Sending CTA URL message with image header..."

begin
  response = client.messages.send_interactive_cta_url(
    phone_number_id: phone_number_id,
    to: recipient,
    header: {
      type: 'image',
      image: {
        link: 'https://example.com/banner.jpg'
      }
    },
    body_text: 'New collection just dropped! Browse our latest arrivals.',
    display_text: 'View Collection',
    url: 'https://shop.example.com/new-arrivals'
  )
  
  puts "✓ Message sent! ID: #{response.messages.first.id}\n\n"
rescue StandardError => e
  puts "✗ Error: #{e.message}\n\n"
end

# 3. INTERACTIVE CTA URL - Video Header

puts "3. Sending CTA URL message with video header..."

begin
  response = client.messages.send_interactive_cta_url(
    phone_number_id: phone_number_id,
    to: recipient,
    header: {
      type: 'video',
      video: {
        link: 'https://example.com/product-demo.mp4'
      }
    },
    body_text: 'Watch our product in action! See how it can transform your daily routine.',
    display_text: 'Learn More',
    url: 'https://example.com/product-details',
    footer_text: 'Free shipping available'
  )
  
  puts "✓ Message sent! ID: #{response.messages.first.id}\n\n"
rescue StandardError => e
  puts "✗ Error: #{e.message}\n\n"
end

# 4. INTERACTIVE CTA URL - Document Header

puts "4. Sending CTA URL message with document header..."

begin
  response = client.messages.send_interactive_cta_url(
    phone_number_id: phone_number_id,
    to: recipient,
    header: {
      type: 'document',
      document: {
        link: 'https://example.com/catalog.pdf',
        filename: 'catalog.pdf'
      }
    },
    body_text: 'Download our full catalog and explore all our products.',
    display_text: 'View Online',
    url: 'https://catalog.example.com'
  )
  
  puts "✓ Message sent! ID: #{response.messages.first.id}\n\n"
rescue StandardError => e
  puts "✗ Error: #{e.message}\n\n"
end

# 5. INTERACTIVE CTA URL - No Header

puts "5. Sending CTA URL message without header..."

begin
  response = client.messages.send_interactive_cta_url(
    phone_number_id: phone_number_id,
    to: recipient,
    body_text: 'Join our exclusive members club and get access to special deals!',
    display_text: 'Join Now',
    url: 'https://members.example.com/signup'
  )
  
  puts "✓ Message sent! ID: #{response.messages.first.id}\n\n"
rescue StandardError => e
  puts "✗ Error: #{e.message}\n\n"
end

# 6. CATALOG MESSAGE

puts "6. Sending catalog message..."

begin
  response = client.messages.send_interactive_catalog_message(
    phone_number_id: phone_number_id,
    to: recipient,
    body_text: 'Browse our entire product catalog on WhatsApp!',
    thumbnail_product_retailer_id: 'SKU-001',  # Product SKU to show as thumbnail
    footer_text: 'Tap to explore products'
  )
  
  puts "✓ Catalog message sent! ID: #{response.messages.first.id}\n\n"
rescue StandardError => e
  puts "✗ Error: #{e.message}\n\n"
end

# 7. CATALOG MESSAGE - Minimal

puts "7. Sending minimal catalog message..."

begin
  response = client.messages.send_interactive_catalog_message(
    phone_number_id: phone_number_id,
    to: recipient,
    body_text: 'Check out our products!',
    thumbnail_product_retailer_id: 'FEATURED-PRODUCT-123'
  )
  
  puts "✓ Catalog message sent! ID: #{response.messages.first.id}\n\n"
rescue StandardError => e
  puts "✗ Error: #{e.message}\n\n"
end

# 8. VALIDATION EXAMPLES

puts "8. Testing validation...\n"

# Test body text length limit
puts "  Testing body text length validation..."
begin
  long_text = 'a' * 1025  # Exceeds 1024 character limit
  client.messages.send_interactive_cta_url(
    phone_number_id: phone_number_id,
    to: recipient,
    body_text: long_text,
    display_text: 'Click',
    url: 'https://example.com'
  )
  puts "  ✗ Validation failed - should have raised error\n"
rescue ArgumentError => e
  puts "  ✓ Validation passed: #{e.message}\n"
end

# Test display text length limit
puts "  Testing display text length validation..."
begin
  client.messages.send_interactive_cta_url(
    phone_number_id: phone_number_id,
    to: recipient,
    body_text: 'Test message',
    display_text: 'This is way too long for a button',  # Exceeds 20 characters
    url: 'https://example.com'
  )
  puts "  ✗ Validation failed - should have raised error\n"
rescue ArgumentError => e
  puts "  ✓ Validation passed: #{e.message}\n"
end

# Test URL validation
puts "  Testing URL validation..."
begin
  client.messages.send_interactive_cta_url(
    phone_number_id: phone_number_id,
    to: recipient,
    body_text: 'Test message',
    display_text: 'Click',
    url: 'ftp://invalid-protocol.com'  # Invalid protocol
  )
  puts "  ✗ Validation failed - should have raised error\n"
rescue ArgumentError => e
  puts "  ✓ Validation passed: #{e.message}\n"
end

# Test footer text length
puts "  Testing footer text length validation..."
begin
  long_footer = 'a' * 61  # Exceeds 60 character limit
  client.messages.send_interactive_cta_url(
    phone_number_id: phone_number_id,
    to: recipient,
    body_text: 'Test message',
    display_text: 'Click',
    url: 'https://example.com',
    footer_text: long_footer
  )
  puts "  ✗ Validation failed - should have raised error\n"
rescue ArgumentError => e
  puts "  ✓ Validation passed: #{e.message}\n"
end

# Test invalid header type
puts "  Testing invalid header type validation..."
begin
  client.messages.send_interactive_cta_url(
    phone_number_id: phone_number_id,
    to: recipient,
    header: {
      type: 'audio',  # Invalid type for CTA URL
      audio: { id: 'audio_id' }
    },
    body_text: 'Test message',
    display_text: 'Click',
    url: 'https://example.com'
  )
  puts "  ✗ Validation failed - should have raised error\n"
rescue ArgumentError => e
  puts "  ✓ Validation passed: #{e.message}\n"
end

# Test missing media in header
puts "  Testing missing media in header validation..."
begin
  client.messages.send_interactive_cta_url(
    phone_number_id: phone_number_id,
    to: recipient,
    header: {
      type: 'image'
      # Missing 'image' field
    },
    body_text: 'Test message',
    display_text: 'Click',
    url: 'https://example.com'
  )
  puts "  ✗ Validation failed - should have raised error\n"
rescue ArgumentError => e
  puts "  ✓ Validation passed: #{e.message}\n"
end

puts "\n=== All examples completed! ===\n"

# USE CASES

puts "\n=== Real-World Use Cases ===\n"

# E-commerce: Product promotion
def send_product_promotion(client, phone_number_id, customer_phone)
  client.messages.send_interactive_cta_url(
    phone_number_id: phone_number_id,
    to: customer_phone,
    header: {
      type: 'image',
      image: { link: 'https://shop.example.com/products/summer-dress.jpg' }
    },
    body_text: '🌟 Summer Sale! Get 40% off this beautiful dress. Limited stock available!',
    display_text: 'Buy Now',
    url: 'https://shop.example.com/products/summer-dress?utm_campaign=whatsapp',
    footer_text: 'Free shipping on orders over $50'
  )
end

# Event Registration
def send_event_registration(client, phone_number_id, attendee_phone)
  client.messages.send_interactive_cta_url(
    phone_number_id: phone_number_id,
    to: attendee_phone,
    header: {
      type: 'video',
      video: { link: 'https://events.example.com/preview.mp4' }
    },
    body_text: '🎉 Join us for the biggest tech conference of the year! Early bird tickets now available.',
    display_text: 'Register',
    url: 'https://events.example.com/techcon2024/register',
    footer_text: 'Limited seats available'
  )
end

# Customer Support: Knowledge Base
def send_support_article(client, phone_number_id, customer_phone)
  client.messages.send_interactive_cta_url(
    phone_number_id: phone_number_id,
    to: customer_phone,
    header: {
      type: 'document',
      document: {
        link: 'https://support.example.com/guides/getting-started.pdf',
        filename: 'getting-started.pdf'
      }
    },
    body_text: 'Need help getting started? Check out our comprehensive guide!',
    display_text: 'View Guide',
    url: 'https://support.example.com/getting-started'
  )
end

# Restaurant: Menu and Ordering
def send_restaurant_menu(client, phone_number_id, customer_phone)
  client.messages.send_interactive_catalog_message(
    phone_number_id: phone_number_id,
    to: customer_phone,
    body_text: '🍕 Hungry? Browse our full menu and order for delivery!',
    thumbnail_product_retailer_id: 'PIZZA-MARGHERITA',
    footer_text: 'Delivery in 30 minutes or less'
  )
end

puts "✓ Use case examples defined and ready to use!\n"
