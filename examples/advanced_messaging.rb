# frozen_string_literal: true

# WhatsApp Advanced Messaging Features Examples
# Demonstrates voice notes, group messaging, location requests

require 'kapso-client-ruby'
require 'dotenv'

Dotenv.load

# Initialize client
client = KapsoClientRuby::Client.new(
  access_token: ENV['WHATSAPP_ACCESS_TOKEN']
)

phone_number_id = ENV['PHONE_NUMBER_ID']
recipient = '+1234567890'
group_id = ENV['GROUP_ID'] || '120363XXXXXXXXX@g.us'  # WhatsApp group ID format

puts "=== Advanced Messaging Features (Week 4) ===\n\n"

# 1. VOICE NOTES

puts "1. Sending voice note..."

begin
  response = client.messages.send_audio(
    phone_number_id: phone_number_id,
    to: recipient,
    audio: {
      link: 'https://example.com/voice-message.ogg'  # OGG/OPUS format for voice notes
    },
    voice: true  # Set to true for voice notes
  )
  
  puts "✓ Voice note sent! ID: #{response.messages.first.id}\n\n"
rescue StandardError => e
  puts "✗ Error: #{e.message}\n\n"
end

# Regular audio (not a voice note)
puts "1b. Sending regular audio..."

begin
  response = client.messages.send_audio(
    phone_number_id: phone_number_id,
    to: recipient,
    audio: { link: 'https://example.com/music.mp3' },
    voice: false  # Or omit - defaults to false
  )
  
  puts "✓ Audio sent! ID: #{response.messages.first.id}\n\n"
rescue StandardError => e
  puts "✗ Error: #{e.message}\n\n"
end

# 2. GROUP MESSAGING

puts "2. Sending text message to group..."

begin
  response = client.messages.send_text(
    phone_number_id: phone_number_id,
    to: group_id,
    body: 'Hello everyone! This is a group message.',
    recipient_type: 'group'  # Set to 'group' for group messages
  )
  
  puts "✓ Group message sent! ID: #{response.messages.first.id}\n\n"
rescue StandardError => e
  puts "✗ Error: #{e.message}\n\n"
end

# Sending image to group
puts "2b. Sending image to group..."

begin
  response = client.messages.send_image(
    phone_number_id: phone_number_id,
    to: group_id,
    image: {
      link: 'https://example.com/team-photo.jpg'
    },
    caption: 'Team photo from our last event!',
    recipient_type: 'group'
  )
  
  puts "✓ Group image sent! ID: #{response.messages.first.id}\n\n"
rescue StandardError => e
  puts "✗ Error: #{e.message}\n\n"
end

#  Sending video to group
puts "2c. Sending video to group..."

begin
  response = client.messages.send_video(
    phone_number_id: phone_number_id,
    to: group_id,
    video: {
      link: 'https://example.com/presentation.mp4'
    },
    caption: 'Check out our new product demo!',
    recipient_type: 'group'
  )
  
  puts "✓ Group video sent! ID: #{response.messages.first.id}\n\n"
rescue StandardError => e
  puts "✗ Error: #{e.message}\n\n"
end

# 3. LOCATION REQUEST

puts "3. Requesting user location..."

begin
  response = client.messages.send_interactive_location_request(
    phone_number_id: phone_number_id,
    to: recipient,
    body_text: 'Please share your location so we can provide better service.',
    footer_text: 'Your location will only be used for this delivery'
  )
  
  puts "✓ Location request sent! ID: #{response.messages.first.id}\n\n"
rescue StandardError => e
  puts "✗ Error: #{e.message}\n\n"
end

# Location request with header
puts "3b. Location request with image header..."

begin
  response = client.messages.send_interactive_location_request(
    phone_number_id: phone_number_id,
    to: recipient,
    header: {
      type: 'image',
      image: { link: 'https://example.com/map-icon.png' }
    },
    body_text: 'Help us serve you better by sharing your current location.',
    footer_text: 'Tap to share location'
  )
  
  puts "✓ Location request with header sent! ID: #{response.messages.first.id}\n\n"
rescue StandardError => e
  puts "✗ Error: #{e.message}\n\n"
end

# 4. VALIDATION TESTS

puts "4. Testing validations...\n"

# Test invalid recipient_type
puts "  Testing recipient_type validation..."
begin
  client.messages.send_text(
    phone_number_id: phone_number_id,
    to: recipient,
    body: 'Test',
    recipient_type: 'broadcast'  # Invalid type
  )
  puts "  ✗ Validation failed\n"
rescue ArgumentError => e
  puts "  ✓ Validation passed: #{e.message}\n"
end

puts "\n=== All advanced features demonstrated! ===\n"

# USE CASES

puts "\n=== Real-World Use Cases ===\n"

# Customer Support: Voice response
def send_voice_support_message(client, phone_number_id, customer_phone)
  client.messages.send_audio(
    phone_number_id: phone_number_id,
    to: customer_phone,
    audio: { link: 'https://support.example.com/responses/how-to-reset-password.ogg' },
    voice: true
  )
end

# Team Announcements: Group messaging
def send_team_announcement(client, phone_number_id, team_group_id)
  client.messages.send_text(
    phone_number_id: phone_number_id,
    to: team_group_id,
    body: '📢 Team Meeting Alert: All-hands meeting tomorrow at 10 AM in Conference Room A.',
    recipient_type: 'group'
  )
end

# Delivery Service: Location request
def request_delivery_location(client, phone_number_id, customer_phone)
  client.messages.send_interactive_location_request(
    phone_number_id: phone_number_id,
    to: customer_phone,
    header: {
      type: 'text',
      text: 'Delivery Service'
    },
    body_text: '🚚 Your order is ready for delivery! Please share your current location for accurate delivery.',
    footer_text: 'We respect your privacy'
  )
end

# Educational: Group study materials
def share_study_materials_with_group(client, phone_number_id, study_group_id)
  client.messages.send_video(
    phone_number_id: phone_number_id,
    to: study_group_id,
    video: { link: 'https://edu.example.com/lectures/physics-101.mp4' },
    caption: '📚 Physics 101 - Lecture 5: Thermodynamics. Watch before next class!',
    recipient_type: 'group'
  )
end

# Real Estate: Property location sharing
def request_property_viewing_location(client, phone_number_id, potential_buyer)
  client.messages.send_interactive_location_request(
    phone_number_id: phone_number_id,
    to: potential_buyer,
    header: {
      type: 'image',
      image: { link: 'https://realestate.example.com/properties/oceanview-villa.jpg' }
    },
    body_text: 'Interested in viewing this property? Share your location and we\'ll calculate the best route for you.',
    footer_text: 'Premium Real Estate Services'
  )
end

# Community Management: Group updates with media
def send_community_update(client, phone_number_id, community_group_id)
  client.messages.send_image(
    phone_number_id: phone_number_id,
    to: community_group_id,
    image: { link: 'https://community.example.com/events/summer-festival-poster.jpg' },
    caption: '🎉 Summer Festival this weekend! Join us for food, music, and fun. See you there!',
    recipient_type: 'group'
  )
end
