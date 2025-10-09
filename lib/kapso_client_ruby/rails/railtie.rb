# frozen_string_literal: true

require 'rails/railtie'

module KapsoClientRuby
  module Rails
    # Rails integration for KapsoClientRuby
    class Railtie < ::Rails::Railtie
      railtie_name :kapso_client_ruby

      # Add kapso configuration to Rails application config
      config.kapso = ActiveSupport::OrderedOptions.new

      # Set default configuration values
      config.before_configuration do |app|
        app.config.kapso.api_key = nil
        app.config.kapso.phone_number_id = nil
        app.config.kapso.business_account_id = nil
        app.config.kapso.api_host = 'https://graph.facebook.com'
        app.config.kapso.api_version = 'v23.0'
        app.config.kapso.timeout = 30
        app.config.kapso.debug = false
        app.config.kapso.logger = nil
        app.config.kapso.retry_on_failure = true
        app.config.kapso.max_retries = 3
      end

      # Initialize Kapso client after Rails application initialization
      initializer 'kapso_client_ruby.configure' do |app|
        KapsoClientRuby.configure do |config|
          config.api_key = app.config.kapso.api_key || ENV['KAPSO_API_KEY']
          config.phone_number_id = app.config.kapso.phone_number_id || ENV['KAPSO_PHONE_NUMBER_ID']
          config.business_account_id = app.config.kapso.business_account_id || ENV['KAPSO_BUSINESS_ACCOUNT_ID']
          config.api_host = app.config.kapso.api_host || ENV.fetch('KAPSO_API_HOST', 'https://graph.facebook.com')
          config.api_version = app.config.kapso.api_version || ENV.fetch('KAPSO_API_VERSION', 'v23.0')
          config.timeout = app.config.kapso.timeout || ENV.fetch('KAPSO_TIMEOUT', 30).to_i
          config.debug = app.config.kapso.debug || ENV.fetch('KAPSO_DEBUG', 'false') == 'true'
          config.logger = app.config.kapso.logger || ::Rails.logger
          config.retry_on_failure = app.config.kapso.retry_on_failure
          config.max_retries = app.config.kapso.max_retries || ENV.fetch('KAPSO_MAX_RETRIES', 3).to_i
        end
      end

      # Add rake tasks
      rake_tasks do
        load 'kapso_client_ruby/rails/tasks.rake'
      end

      # Add generators
      generators do
        require 'kapso_client_ruby/rails/generators/install_generator'
      end
    end
  end
end