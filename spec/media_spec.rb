# frozen_string_literal: true

require 'spec_helper'

RSpec.describe KapsoClientRuby::Resources::Media do
  let(:client) { KapsoClientRuby::Client.new(access_token: 'test_token') }
  let(:media) { described_class.new(client) }
  let(:phone_number_id) { 'test_phone_number_id' }
  let(:media_id) { 'media_123' }

  describe '#upload' do
    let(:file_path) { File.join(__dir__, 'fixtures', 'test_image.jpg') }
    
    before do
      # Create a test fixture file
      FileUtils.mkdir_p(File.dirname(file_path))
      File.write(file_path, 'fake image content')
    end

    after do
      FileUtils.rm_f(file_path)
    end

    it 'uploads media file', :vcr do
      response_body = {
        'id' => media_id,
        'messaging_product' => 'whatsapp'
      }
      
      stub_request(:post, "https://graph.facebook.com/v23.0/#{phone_number_id}/media")
        .to_return(status: 200, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })

      response = media.upload(
        phone_number_id: phone_number_id,
        file: file_path
      )

      expect(response['id']).to eq(media_id)
      expect(response['messaging_product']).to eq('whatsapp')
    end

    it 'uploads with custom type' do
      response_body = { 'id' => media_id }
      
      stub_request(:post, "https://graph.facebook.com/v23.0/#{phone_number_id}/media")
        .to_return(status: 200, body: response_body.to_json)

      response = media.upload(
        phone_number_id: phone_number_id,
        file: file_path,
        type: 'image/jpeg'
      )

      expect(response['id']).to eq(media_id)
    end

    it 'handles file upload errors' do
      stub_request(:post, "https://graph.facebook.com/v23.0/#{phone_number_id}/media")
        .to_return(
          status: 400,
          body: sample_error_response.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      expect {
        media.upload(
          phone_number_id: phone_number_id,
          file: file_path
        )
      }.to raise_error(KapsoClientRuby::Errors::GraphApiError)
    end
  end

  describe '#get_url' do
    it 'retrieves media URL', :vcr do
      response_body = {
        'id' => media_id,
        'url' => 'https://example.com/media.jpg',
        'mime_type' => 'image/jpeg',
        'sha256' => 'abc123',
        'file_size' => 1024,
        'messaging_product' => 'whatsapp'
      }
      
      stub_request(:get, "https://graph.facebook.com/v23.0/#{media_id}")
        .to_return(status: 200, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })

      response = media.get_url(media_id: media_id)

      expect(response['id']).to eq(media_id)
      expect(response['url']).to eq('https://example.com/media.jpg')
      expect(response['mime_type']).to eq('image/jpeg')
    end

    it 'handles media not found' do
      stub_request(:get, "https://graph.facebook.com/v23.0/#{media_id}")
        .to_return(
          status: 404,
          body: {
            'error' => {
              'message' => 'Media not found',
              'type' => 'OAuthException',
              'code' => 100
            }
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      expect {
        media.get_url(media_id: media_id)
      }.to raise_error(KapsoClientRuby::Errors::GraphApiError) do |error|
        expect(error.http_status).to eq(404)
        expect(error.code).to eq(100)
      end
    end
  end

  describe '#download' do
    let(:media_url) { 'https://example.com/media.jpg' }
    let(:media_content) { 'fake image content' }

    context 'with access token auth' do
      it 'downloads media with access token', :vcr do
        # First stub the URL retrieval
        stub_request(:get, "https://graph.facebook.com/v23.0/#{media_id}")
          .to_return(
            status: 200, 
            body: { 'url' => media_url }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
        
        # Then stub the media download
        stub_request(:get, media_url)
          .with(headers: { 'Authorization' => 'Bearer test_token' })
          .to_return(status: 200, body: media_content)

        content = media.download(media_id: media_id)

        expect(content).to eq(media_content)
      end
    end

    context 'with Kapso API key auth' do
      let(:kapso_client) { KapsoClientRuby::Client.new(kapso_api_key: 'test_key', base_url: 'https://app.kapso.ai/api/meta') }
      let(:kapso_media) { described_class.new(kapso_client) }

      it 'downloads media with API key' do
        stub_request(:get, "https://app.kapso.ai/api/meta/v23.0/#{media_id}")
          .to_return(
            status: 200,
            body: { 'url' => media_url }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
        
        stub_request(:get, media_url)
          .with(headers: { 'X-API-Key' => 'test_key' })
          .to_return(status: 200, body: media_content)

        content = kapso_media.download(media_id: media_id)

        expect(content).to eq(media_content)
      end
    end

    it 'handles download errors' do
      stub_request(:get, "https://graph.facebook.com/v23.0/#{media_id}")
        .to_return(
          status: 200,
          body: { 'url' => media_url }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
      
      stub_request(:get, media_url)
        .to_return(status: 403, body: 'Forbidden')

      expect {
        media.download(media_id: media_id)
      }.to raise_error(KapsoClientRuby::Errors::GraphApiError) do |error|
        expect(error.message).to include('Failed to download media')
      end
    end
  end

  describe '#delete' do
    it 'deletes media', :vcr do
      stub_request(:delete, "https://graph.facebook.com/v23.0/#{media_id}")
        .to_return(status: 200, body: { 'success' => true }.to_json, headers: { 'Content-Type' => 'application/json' })

      response = media.delete(media_id: media_id)

      expect(response['success']).to be true
    end

    it 'handles delete errors' do
      stub_request(:delete, "https://graph.facebook.com/v23.0/#{media_id}")
        .to_return(
          status: 400,
          body: sample_error_response.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      expect {
        media.delete(media_id: media_id)
      }.to raise_error(KapsoClientRuby::Errors::GraphApiError)
    end
  end
end