# frozen_string_literal: true

require 'rspec'
require 'webmock/rspec'
require 'vcr'

# Require the gem
require 'kapso_client_ruby'

# Configure WebMock
WebMock.disable_net_connect!(allow_localhost: true)

# Configure VCR
VCR.configure do |config|
  config.cassette_library_dir = 'spec/vcr_cassettes'
  config.hook_into :webmock
  config.configure_rspec_metadata!
  
  # Filter sensitive data from recordings
  config.filter_sensitive_data('<ACCESS_TOKEN>') { ENV['WHATSAPP_ACCESS_TOKEN'] }
  config.filter_sensitive_data('<KAPSO_API_KEY>') { ENV['KAPSO_API_KEY'] }
  config.filter_sensitive_data('<PHONE_NUMBER_ID>') { ENV['PHONE_NUMBER_ID'] }
  config.filter_sensitive_data('<BUSINESS_ACCOUNT_ID>') { ENV['BUSINESS_ACCOUNT_ID'] }
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on Module and main
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Reset configuration before each test
  config.before(:each) do
    KapsoClientRuby.reset_configuration!
  end
end

# Test helpers
module TestHelpers
  def sample_message_response
    {
      'messaging_product' => 'whatsapp',
      'contacts' => [
        {
          'input' => '+1234567890',
          'wa_id' => '1234567890'
        }
      ],
      'messages' => [
        {
          'id' => 'wamid.test_message_id',
          'message_status' => 'accepted'
        }
      ]
    }
  end

  def sample_error_response(code = 131047)
    {
      'error' => {
        'message' => "(##{code}) Test error message",
        'type' => 'OAuthException',
        'code' => code,
        'error_subcode' => 999001,
        'error_data' => {
          'messaging_product' => 'whatsapp',
          'details' => 'Test error details'
        },
        'fbtrace_id' => 'TEST123'
      }
    }
  end

  def stub_whatsapp_request(method, path, response_body = nil, status = 200)
    response_body ||= sample_message_response
    
    stub_request(method, %r{graph\.facebook\.com/v23\.0/#{Regexp.escape(path)}})
      .to_return(
        status: status,
        body: response_body.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  def stub_kapso_request(method, path, response_body = nil, status = 200)
    response_body ||= sample_message_response
    
    stub_request(method, %r{app\.kapso\.ai/api/meta/v23\.0/#{Regexp.escape(path)}})
      .to_return(
        status: status,
        body: response_body.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end
end

RSpec.configure do |config|
  config.include TestHelpers
end