# frozen_string_literal: true

require 'spec_helper'

RSpec.describe KapsoClientRuby::Resources::Messages do
  let(:client) { KapsoClientRuby::Client.new(access_token: 'test_token') }
  let(:messages) { described_class.new(client) }
  let(:phone_number_id) { 'test_phone_number_id' }
  let(:to_number) { '+1234567890' }

  describe '#send_text' do
    it 'sends text message', :vcr do
      stub_whatsapp_request(:post, "#{phone_number_id}/messages", sample_message_response)

      response = messages.send_text(
        from: phone_number_id,
        to: to_number,
        text: 'Hello, World!'
      )

      expect(response['messaging_product']).to eq('whatsapp')
      expect(response['messages'].first['id']).to be_present
    end

    it 'sends text with preview URL' do
      stub_whatsapp_request(:post, "#{phone_number_id}/messages", sample_message_response)

      response = messages.send_text(
        from: phone_number_id,
        to: to_number,
        text: 'Check out https://example.com',
        preview_url: true
      )

      expect(response['messaging_product']).to eq('whatsapp')
    end
  end

  describe '#send_template' do
    it 'sends template message', :vcr do
      stub_whatsapp_request(:post, "#{phone_number_id}/messages", sample_message_response)

      response = messages.send_template(
        from: phone_number_id,
        to: to_number,
        name: 'hello_world',
        language_code: 'en_US'
      )

      expect(response['messaging_product']).to eq('whatsapp')
    end

    it 'sends template with parameters' do
      stub_whatsapp_request(:post, "#{phone_number_id}/messages", sample_message_response)

      response = messages.send_template(
        from: phone_number_id,
        to: to_number,
        name: 'welcome_message',
        language_code: 'en_US',
        components: [
          {
            type: 'body',
            parameters: [
              { type: 'text', text: 'John' }
            ]
          }
        ]
      )

      expect(response['messaging_product']).to eq('whatsapp')
    end
  end

  describe '#send_image' do
    it 'sends image by media ID', :vcr do
      stub_whatsapp_request(:post, "#{phone_number_id}/messages", sample_message_response)

      response = messages.send_image(
        from: phone_number_id,
        to: to_number,
        media_id: 'media_123',
        caption: 'Check out this image!'
      )

      expect(response['messaging_product']).to eq('whatsapp')
    end

    it 'sends image by URL' do
      stub_whatsapp_request(:post, "#{phone_number_id}/messages", sample_message_response)

      response = messages.send_image(
        from: phone_number_id,
        to: to_number,
        link: 'https://example.com/image.jpg'
      )

      expect(response['messaging_product']).to eq('whatsapp')
    end
  end

  describe '#send_document' do
    it 'sends document', :vcr do
      stub_whatsapp_request(:post, "#{phone_number_id}/messages", sample_message_response)

      response = messages.send_document(
        from: phone_number_id,
        to: to_number,
        media_id: 'doc_123',
        filename: 'report.pdf',
        caption: 'Monthly report'
      )

      expect(response['messaging_product']).to eq('whatsapp')
    end
  end

  describe '#send_audio' do
    it 'sends audio message', :vcr do
      stub_whatsapp_request(:post, "#{phone_number_id}/messages", sample_message_response)

      response = messages.send_audio(
        from: phone_number_id,
        to: to_number,
        media_id: 'audio_123'
      )

      expect(response['messaging_product']).to eq('whatsapp')
    end
  end

  describe '#send_video' do
    it 'sends video message', :vcr do
      stub_whatsapp_request(:post, "#{phone_number_id}/messages", sample_message_response)

      response = messages.send_video(
        from: phone_number_id,
        to: to_number,
        media_id: 'video_123',
        caption: 'Check out this video!'
      )

      expect(response['messaging_product']).to eq('whatsapp')
    end
  end

  describe '#send_sticker' do
    it 'sends sticker', :vcr do
      stub_whatsapp_request(:post, "#{phone_number_id}/messages", sample_message_response)

      response = messages.send_sticker(
        from: phone_number_id,
        to: to_number,
        media_id: 'sticker_123'
      )

      expect(response['messaging_product']).to eq('whatsapp')
    end
  end

  describe '#send_location' do
    it 'sends location', :vcr do
      stub_whatsapp_request(:post, "#{phone_number_id}/messages", sample_message_response)

      response = messages.send_location(
        from: phone_number_id,
        to: to_number,
        latitude: 37.7749,
        longitude: -122.4194,
        name: 'San Francisco',
        address: 'San Francisco, CA'
      )

      expect(response['messaging_product']).to eq('whatsapp')
    end
  end

  describe '#send_contact' do
    it 'sends contact', :vcr do
      stub_whatsapp_request(:post, "#{phone_number_id}/messages", sample_message_response)

      response = messages.send_contact(
        from: phone_number_id,
        to: to_number,
        contacts: [
          {
            name: {
              formatted_name: 'John Doe',
              first_name: 'John',
              last_name: 'Doe'
            },
            phones: [
              {
                phone: '+1234567890',
                type: 'HOME'
              }
            ]
          }
        ]
      )

      expect(response['messaging_product']).to eq('whatsapp')
    end
  end

  describe '#send_interactive' do
    it 'sends interactive button message', :vcr do
      stub_whatsapp_request(:post, "#{phone_number_id}/messages", sample_message_response)

      response = messages.send_interactive(
        from: phone_number_id,
        to: to_number,
        type: 'button',
        body: 'Choose an option:',
        action: {
          buttons: [
            {
              type: 'reply',
              reply: {
                id: 'option_1',
                title: 'Option 1'
              }
            }
          ]
        }
      )

      expect(response['messaging_product']).to eq('whatsapp')
    end

    it 'sends interactive list message' do
      stub_whatsapp_request(:post, "#{phone_number_id}/messages", sample_message_response)

      response = messages.send_interactive(
        from: phone_number_id,
        to: to_number,
        type: 'list',
        body: 'Select from the list:',
        action: {
          button: 'Select',
          sections: [
            {
              title: 'Section 1',
              rows: [
                {
                  id: 'row_1',
                  title: 'Row 1',
                  description: 'Description for row 1'
                }
              ]
            }
          ]
        }
      )

      expect(response['messaging_product']).to eq('whatsapp')
    end
  end

  describe '#send_reaction' do
    it 'sends reaction', :vcr do
      stub_whatsapp_request(:post, "#{phone_number_id}/messages", sample_message_response)

      response = messages.send_reaction(
        from: phone_number_id,
        to: to_number,
        message_id: 'msg_123',
        emoji: '👍'
      )

      expect(response['messaging_product']).to eq('whatsapp')
    end

    it 'removes reaction' do
      stub_whatsapp_request(:post, "#{phone_number_id}/messages", sample_message_response)

      response = messages.send_reaction(
        from: phone_number_id,
        to: to_number,
        message_id: 'msg_123'
      )

      expect(response['messaging_product']).to eq('whatsapp')
    end
  end

  describe '#mark_as_read' do
    it 'marks message as read', :vcr do
      stub_whatsapp_request(:post, "#{phone_number_id}/messages", { 'success' => true })

      response = messages.mark_as_read(
        from: phone_number_id,
        message_id: 'msg_123'
      )

      expect(response['success']).to be true
    end
  end
end