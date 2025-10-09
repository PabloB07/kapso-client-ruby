# frozen_string_literal: true

require_relative 'kapso_client_ruby/version'
require_relative 'kapso_client_ruby/client'
require_relative 'kapso_client_ruby/errors'
require_relative 'kapso_client_ruby/types'
require_relative 'kapso_client_ruby/resources/messages'
require_relative 'kapso_client_ruby/resources/media'
require_relative 'kapso_client_ruby/resources/templates'
require_relative 'kapso_client_ruby/resources/phone_numbers'
require_relative 'kapso_client_ruby/resources/calls'
require_relative 'kapso_client_ruby/resources/conversations'
require_relative 'kapso_client_ruby/resources/contacts'

module KapsoClientRuby
  class << self
    # Configure default logging
    def logger
      @logger ||= Logger.new($stdout).tap do |log|
        log.level = Logger::INFO
        log.formatter = proc do |severity, datetime, progname, msg|
          "[#{datetime}] #{severity} #{progname}: #{msg}\n"
        end
      end
    end

    def logger=(logger)
      @logger = logger
    end

    # Global configuration
    def configure
      yield(configuration)
    end

    def configuration
      @configuration ||= Configuration.new
    end

    def reset_configuration!
      @configuration = Configuration.new
    end
  end

  class Configuration
    attr_accessor :debug, :timeout, :open_timeout, :max_retries, :retry_delay,
                  :access_token, :kapso_api_key, :base_url, :api_version

    def initialize
      @debug = false
      @timeout = 60
      @open_timeout = 10
      @max_retries = 3
      @retry_delay = 1.0
      @base_url = 'https://graph.facebook.com'
      @api_version = 'v23.0'
      @access_token = nil
      @kapso_api_key = nil
    end

    def kapso_proxy?
      !@kapso_api_key.nil? && @base_url&.include?('kapso')
    end

    def valid?
      !@access_token.nil? || !@kapso_api_key.nil?
    end
  end
end