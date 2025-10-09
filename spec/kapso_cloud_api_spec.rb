# frozen_string_literal: true

require 'spec_helper'

RSpec.describe KapsoClientRuby do
  describe '.configure' do
    it 'yields configuration block' do
      described_class.configure do |config|
        config.access_token = 'test_token'
        config.debug = true
      end

      expect(described_class.configuration.access_token).to eq('test_token')
      expect(described_class.configuration.debug).to be true
    end
  end

  describe '.configuration' do
    it 'returns configuration instance' do
      expect(described_class.configuration).to be_a(KapsoClientRuby::Configuration)
    end
  end

  describe '.logger' do
    it 'returns logger instance' do
      expect(described_class.logger).to respond_to(:info)
      expect(described_class.logger).to respond_to(:debug)
      expect(described_class.logger).to respond_to(:error)
    end
  end

  describe 'version' do
    it 'has a version number' do
      expect(KapsoClientRuby::VERSION).not_to be nil
      expect(KapsoClientRuby::VERSION).to match(/\d+\.\d+\.\d+/)
    end
  end

  describe KapsoClientRuby::Configuration do
    let(:config) { described_class.new }

    it 'has default values' do
      expect(config.base_url).to eq('https://graph.facebook.com')
      expect(config.api_version).to eq('v23.0')
      expect(config.timeout).to eq(30)
      expect(config.debug).to be false
      expect(config.access_token).to be_nil
      expect(config.kapso_api_key).to be_nil
    end

    it 'allows setting custom values' do
      config.base_url = 'https://custom.api.com'
      config.api_version = 'v24.0'
      config.timeout = 60
      config.debug = true
      config.access_token = 'token123'
      config.kapso_api_key = 'key456'

      expect(config.base_url).to eq('https://custom.api.com')
      expect(config.api_version).to eq('v24.0')
      expect(config.timeout).to eq(60)
      expect(config.debug).to be true
      expect(config.access_token).to eq('token123')
      expect(config.kapso_api_key).to eq('key456')
    end

    describe '#kapso_proxy?' do
      it 'returns true when using Kapso' do
        config.kapso_api_key = 'test_key'
        config.base_url = 'https://app.kapso.ai/api/meta'
        
        expect(config.kapso_proxy?).to be true
      end

      it 'returns false when not using Kapso' do
        config.access_token = 'test_token'
        config.base_url = 'https://graph.facebook.com'
        
        expect(config.kapso_proxy?).to be false
      end
    end

    describe '#valid?' do
      it 'is valid with access token' do
        config.access_token = 'test_token'
        expect(config.valid?).to be true
      end

      it 'is valid with Kapso API key' do
        config.kapso_api_key = 'test_key'
        expect(config.valid?).to be true
      end

      it 'is invalid without authentication' do
        expect(config.valid?).to be false
      end
    end
  end
end