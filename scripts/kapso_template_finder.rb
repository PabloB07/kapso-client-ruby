#!/usr/bin/env ruby
# frozen_string_literal: true

require 'dotenv/load' rescue nil
require_relative '../lib/kapso_client_ruby'

puts "🔍 Kapso Template Finder"
puts "=" * 30

kapso_api_key = ENV['KAPSO_API_KEY']
phone_number_id = ENV['PHONE_NUMBER_ID']
business_account_id = ENV['BUSINESS_ACCOUNT_ID']

unless kapso_api_key && phone_number_id
  puts "❌ Missing credentials. Run: ruby sdk_test.rb"
  exit 1
end

client = KapsoClientRuby::Client.new(
  kapso_api_key: kapso_api_key,
  base_url: ENV['WHATSAPP_BASE_URL'] || 'https://app.kapso.ai/api/meta'
)

puts "Phone: #{phone_number_id}"
puts "Business Account: #{business_account_id || 'Not set'}"

print "Destination (+56912345678): "
to_number = gets.chomp
to_number = "+56912345678" if to_number.empty?

puts "\n📋 Finding Templates..."
found_templates = []

# Try Business Account if available
if business_account_id
  puts "Checking Business Account..."
  begin
    response = client.templates.list(business_account_id: business_account_id)
    if response.data && response.data.any?
      response.data.each do |template|
        found_templates << {
          name: template.name,
          language: template.language,
          status: template.status
        }
        puts "✅ #{template.name} (#{template.language}) - #{template.status}"
      end
    end
  rescue => e
    puts "❌ Error: #{e.message}"
  end
end

# Test common names if none found
if found_templates.empty?
  puts "Testing common template names..."
  ["hello_world", "welcome_message"].each do |name|
    print "Testing #{name}... "
    begin
      client.messages.send_template(
        phone_number_id: phone_number_id,
        to: to_number,
        name: name,
        language: "en_US"
      )
      puts "✅ WORKS"
      found_templates << { name: name, language: "en_US", status: "APPROVED" }
    rescue => e
      puts "❌ Not found" if e.message.include?("does not exist")
    end
  end
end

puts "\n=" * 30
puts "📊 RESULTS"

if found_templates.any?
  puts "Found #{found_templates.length} template(s):"
  found_templates.each do |t|
    puts "\n• #{t[:name]} (#{t[:language]})"
    puts "  Status: #{t[:status]}"
  end
  puts "\n🎯 Templates work 24/7 - no time limits!"
else
  puts "No templates found"
  puts "\nNext steps:"
  puts "1. Add BUSINESS_ACCOUNT_ID to .env"
  puts "2. Create templates in Kapso dashboard"
end

puts "\n💡 Templates solve the 24-hour problem!"
