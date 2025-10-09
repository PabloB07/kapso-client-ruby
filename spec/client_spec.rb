# frozen_string_literal: true

require 'spec_helper'

RSpec.describe KapsoClientRuby::Client do
  let(:access_token) { 'test_access_token' }
  let(:kapso_api_key) { 'test_kapso_key' }
  let(:phone_number_id) { 'test_phone_number_id' }

  describe 'initialization' do
    it 'initializes with access token' do
      client = described_class.new(access_token: access_token)
      expect(client.access_token).to eq(access_token)
      expect(client.kapso_proxy?).to be false
    end

    it 'initializes with Kapso API key' do
      client = described_class.new(
        kapso_api_key: kapso_api_key,
        base_url: 'https://app.kapso.ai/api/meta'
      )
      expect(client.kapso_api_key).to eq(kapso_api_key)
      expect(client.kapso_proxy?).to be true
    end

    it 'raises error when neither token nor key provided' do
      expect {
        described_class.new
      }.to raise_error(KapsoClientRuby::Errors::ConfigurationError)
    end

    it 'sets debug mode' do
      client = described_class.new(access_token: access_token, debug: true)
      expect(client.debug).to be true
    end
  end

  describe 'resource accessors' do
    let(:client) { described_class.new(access_token: access_token) }

    it 'provides messages resource' do
      expect(client.messages).to be_a(KapsoClientRuby::Resources::Messages)
    end

    it 'provides media resource' do
      expect(client.media).to be_a(KapsoClientRuby::Resources::Media)
    end

    it 'provides templates resource' do
      expect(client.templates).to be_a(KapsoClientRuby::Resources::Templates)
    end

    it 'provides phone numbers resource' do
      expect(client.phone_numbers).to be_a(KapsoClientRuby::Resources::PhoneNumbers)
    end

    it 'provides calls resource' do
      expect(client.calls).to be_a(KapsoClientRuby::Resources::Calls)
    end

    it 'provides conversations resource' do
      expect(client.conversations).to be_a(KapsoClientRuby::Resources::Conversations)
    end

    it 'provides contacts resource' do
      expect(client.contacts).to be_a(KapsoClientRuby::Resources::Contacts)
    end
  end

  describe 'HTTP requests', :vcr do
    let(:client) { described_class.new(access_token: access_token) }

    it 'makes GET requests' do
      stub_whatsapp_request(:get, phone_number_id, { 'id' => phone_number_id })
      
      response = client.request(:get, phone_number_id, response_type: :json)
      expect(response['id']).to eq(phone_number_id)
    end

    it 'makes POST requests' do
      stub_whatsapp_request(:post, "#{phone_number_id}/messages")
      
      response = client.request(
        :post, 
        "#{phone_number_id}/messages",
        body: { messaging_product: 'whatsapp', to: '+1234567890', type: 'text', text: { body: 'test' } }.to_json,
        response_type: :json
      )
      
      expect(response['messaging_product']).to eq('whatsapp')
    end

    it 'handles error responses' do
      stub_request(:post, %r{graph\.facebook\.com})
        .to_return(
          status: 400,
          body: sample_error_response.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      expect {
        client.request(:post, "#{phone_number_id}/messages", body: {}.to_json)
      }.to raise_error(KapsoClientRuby::Errors::GraphApiError) do |error|
        expect(error.http_status).to eq(400)
        expect(error.code).to eq(131047)
        expect(error.category).to eq(:reengagement_window)
      end
    end
  end

  describe 'URL building' do
    let(:client) { described_class.new(access_token: access_token) }

    it 'builds correct URLs with default base' do
      # This is a private method, so we test it indirectly
      stub_whatsapp_request(:get, phone_number_id)
      client.request(:get, phone_number_id)
      
      expect(WebMock).to have_requested(:get, "https://graph.facebook.com/v23.0/#{phone_number_id}")
    end

    it 'builds URLs with query parameters' do
      stub_request(:get, "https://graph.facebook.com/v23.0/#{phone_number_id}")
        .with(query: { 'fields' => 'id,name' })
        .to_return(status: 200, body: {}.to_json)
      
      client.request(:get, phone_number_id, query: { fields: 'id,name' })
      
      expect(WebMock).to have_requested(:get, "https://graph.facebook.com/v23.0/#{phone_number_id}")
        .with(query: { 'fields' => 'id,name' })
    end
  end

  describe 'authentication headers' do
    it 'sets Authorization header for access token' do
      client = described_class.new(access_token: access_token)
      
      stub_request(:get, %r{graph\.facebook\.com})
        .with(headers: { 'Authorization' => "Bearer #{access_token}" })
        .to_return(status: 200, body: {}.to_json)
      
      client.request(:get, phone_number_id)
      
      expect(WebMock).to have_requested(:get, %r{graph\.facebook\.com})
        .with(headers: { 'Authorization' => "Bearer #{access_token}" })
    end

    it 'sets X-API-Key header for Kapso API key' do
      client = described_class.new(
        kapso_api_key: kapso_api_key,
        base_url: 'https://app.kapso.ai/api/meta'
      )
      
      stub_request(:get, %r{app\.kapso\.ai})
        .with(headers: { 'X-API-Key' => kapso_api_key })
        .to_return(status: 200, body: {}.to_json)
      
      client.request(:get, phone_number_id)
      
      expect(WebMock).to have_requested(:get, %r{app\.kapso\.ai})
        .with(headers: { 'X-API-Key' => kapso_api_key })
    end
  end
end