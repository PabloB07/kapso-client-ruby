#!/usr/bin/env ruby
# frozen_string_literal: true

require 'dotenv/load' rescue nil
require_relative '../lib/kapso_client_ruby'

puts "🚀 Kapso API Quick Test"

# Get credentials
kapso_api_key = ENV['KAPSO_API_KEY']
phone_number_id = ENV['PHONE_NUMBER_ID']

unless kapso_api_key && phone_number_id
  puts "❌ Missing credentials. Run: ruby sdk_test.rb"
  exit 1
end

client = KapsoClientRuby::Client.new(
  kapso_api_key: kapso_api_key,
  base_url: ENV['WHATSAPP_BASE_URL'] || 'https://app.kapso.ai/api/meta',
  debug: true
)

puts "API Key: ***#{kapso_api_key[-4..-1]} | Phone: #{phone_number_id}"

print "Destination (+56912345678): "
to_number = gets.chomp

puts "📱 Sending..."

begin
  response = client.messages.send_text(
    phone_number_id: phone_number_id,
    to: to_number,
    body: "Test from Ruby SDK - #{Time.now.strftime('%H:%M')}"
  )
  
  puts "✅ SUCCESS! Message ID: #{response.messages.first.id}"

rescue KapsoClientRuby::Errors::GraphApiError => e
  puts "❌ ERROR #{e.http_status}: #{e.message}"
  
  # Check for specific 24-hour window error
  if e.message.include?("24 hours") || e.message.include?("Re-engagement")
    puts "⏰ 24-HOUR WINDOW EXPIRED!"
    puts "💡 Solutions via Kapso.ai:"
    puts "   • Check Kapso dashboard for approved templates"
    puts "   • Run: ruby kapso_template_finder.rb (discover templates)"
    puts "   • Run: ruby template_test.rb (test template sending)"
  else
    case e.http_status
    when 401
      puts "💡 Check Kapso API key in dashboard"
    when 400  
      puts "💡 Check phone number ID or destination format"
    else
      puts "💡 Contact Kapso support"
    end
  end
end
