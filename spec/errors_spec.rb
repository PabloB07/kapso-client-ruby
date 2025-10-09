# frozen_string_literal: true

require 'spec_helper'

RSpec.describe KapsoClientRuby::Errors::GraphApiError do
  describe '#initialize' do
    it 'initializes with basic error info' do
      error = described_class.new(
        message: 'Test error',
        code: 100,
        http_status: 400
      )

      expect(error.message).to eq('Test error')
      expect(error.code).to eq(100)
      expect(error.http_status).to eq(400)
      expect(error.category).to eq(:unknown)
      expect(error.retry_after).to be_nil
      expect(error.rate_limit?).to be false
    end

    it 'categorizes rate limit errors' do
      error = described_class.new(
        message: 'Rate limit exceeded',
        code: 4,
        http_status: 429
      )

      expect(error.category).to eq(:rate_limit_hit)
      expect(error.rate_limit?).to be true
    end

    it 'categorizes permission errors' do
      error = described_class.new(
        message: 'Permission denied',
        code: 200,
        http_status: 403
      )

      expect(error.category).to eq(:permissions)
    end

    it 'extracts retry_after from headers' do
      error = described_class.new(
        message: 'Rate limit exceeded',
        code: 4,
        http_status: 429,
        headers: { 'retry-after' => '60' }
      )

      expect(error.retry_after).to eq(60)
    end
  end

  describe '#categorize_error' do
    it 'categorizes authentication errors' do
      error = described_class.new(message: 'Invalid token', code: 190, http_status: 401)
      expect(error.category).to eq(:authentication)
    end

    it 'categorizes validation errors' do
      error = described_class.new(message: 'Invalid phone number', code: 131051, http_status: 400)
      expect(error.category).to eq(:generic_user_error)
    end

    it 'categorizes reengagement window errors' do
      error = described_class.new(message: 'Message undeliverable', code: 131047, http_status: 400)
      expect(error.category).to eq(:reengagement_window)
    end

    it 'categorizes template errors' do
      error = described_class.new(message: 'Template not found', code: 132000, http_status: 400)
      expect(error.category).to eq(:template_format)
    end

    it 'categorizes media errors' do
      error = described_class.new(message: 'Media upload failed', code: 131009, http_status: 400)
      expect(error.category).to eq(:media_upload)
    end

    it 'defaults to unknown category' do
      error = described_class.new(message: 'Unknown error', code: 999999, http_status: 500)
      expect(error.category).to eq(:unknown)
    end
  end

  describe '#retry_hint' do
    it 'suggests retry for rate limits' do
      error = described_class.new(message: 'Rate limit', code: 4, http_status: 429)
      expect(error.retry_hint).to eq(:retry_after_delay)
    end

    it 'suggests no retry for authentication errors' do
      error = described_class.new(message: 'Invalid token', code: 190, http_status: 401)
      expect(error.retry_hint).to eq(:do_not_retry)
    end

    it 'suggests retry for temporary errors' do
      error = described_class.new(message: 'Temporary error', code: 1, http_status: 500)
      expect(error.retry_hint).to eq(:retry_after_delay)
    end

    it 'suggests immediate retry for certain errors' do
      error = described_class.new(message: 'Transient error', code: 2, http_status: 500)
      expect(error.retry_hint).to eq(:retry_immediately)
    end
  end

  describe '#temporary?' do
    it 'identifies temporary errors' do
      error = described_class.new(message: 'Temporary error', code: 1, http_status: 500)
      expect(error.temporary?).to be true
    end

    it 'identifies permanent errors' do
      error = described_class.new(message: 'Invalid token', code: 190, http_status: 401)
      expect(error.temporary?).to be false
    end
  end

  describe '.from_response' do
    it 'creates error from API response' do
      response_body = {
        'error' => {
          'message' => 'Invalid phone number format',
          'type' => 'OAuthException',
          'code' => 131051,
          'error_subcode' => 2494055,
          'fbtrace_id' => 'trace123'
        }
      }

      error = described_class.from_response(response_body, 400, {})

      expect(error.message).to eq('Invalid phone number format')
      expect(error.code).to eq(131051)
      expect(error.http_status).to eq(400)
      expect(error.error_type).to eq('OAuthException')
      expect(error.error_subcode).to eq(2494055)
      expect(error.fbtrace_id).to eq('trace123')
    end

    it 'handles responses without error details' do
      response_body = { 'message' => 'Something went wrong' }

      error = described_class.from_response(response_body, 500, {})

      expect(error.message).to eq('Unknown API error')
      expect(error.code).to be_nil
      expect(error.http_status).to eq(500)
    end

    it 'handles empty response' do
      error = described_class.from_response(nil, 500, {})

      expect(error.message).to eq('Unknown API error')
      expect(error.http_status).to eq(500)
    end
  end

  describe '#to_s' do
    it 'formats error message with details' do
      error = described_class.new(
        message: 'Test error',
        code: 100,
        http_status: 400,
        category: :validation
      )

      string_representation = error.to_s
      expect(string_representation).to include('Test error')
      expect(string_representation).to include('Code: 100')
      expect(string_representation).to include('Status: 400')
      expect(string_representation).to include('Category: validation')
    end
  end
end