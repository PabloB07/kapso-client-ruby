# frozen_string_literal: true

require 'faraday'
require 'faraday/multipart'
require 'json'
require 'logger'

module KapsoClientRuby
  class Client
    DEFAULT_BASE_URL = 'https://graph.facebook.com'
    DEFAULT_GRAPH_VERSION = 'v24.0'
    KAPSO_PROXY_PATTERN = /kapso\.ai/

    attr_reader :access_token, :kapso_api_key, :base_url, :graph_version, 
                :logger, :debug, :timeout, :open_timeout, :max_retries, :retry_delay

    def initialize(access_token: nil, kapso_api_key: nil, base_url: nil, 
                   graph_version: nil, logger: nil, debug: nil, timeout: nil, 
                   open_timeout: nil, max_retries: nil, retry_delay: nil)
      
      # Validation
      unless access_token || kapso_api_key
        raise Errors::ConfigurationError, 'Must provide either access_token or kapso_api_key'
      end

      @access_token = access_token
      @kapso_api_key = kapso_api_key
      @base_url = normalize_base_url(base_url || DEFAULT_BASE_URL)
      @graph_version = graph_version || DEFAULT_GRAPH_VERSION
      @kapso_proxy = detect_kapso_proxy(@base_url)
      
      # Configuration with defaults
      config = KapsoClientRuby.configuration
      @logger = logger || KapsoClientRuby.logger
      @debug = debug.nil? ? config.debug : debug
      @timeout = timeout || config.timeout
      @open_timeout = open_timeout || config.open_timeout
      @max_retries = max_retries || config.max_retries
      @retry_delay = retry_delay || config.retry_delay

      # Initialize HTTP client
      @http_client = build_http_client

      # Initialize resource endpoints
      @messages = nil
      @media = nil
      @templates = nil
      @phone_numbers = nil
      @calls = nil
      @conversations = nil
      @contacts = nil
      @flows = nil
    end

    # Resource accessors with lazy initialization
    def messages
      @messages ||= Resources::Messages.new(self)
    end

    def media
      @media ||= Resources::Media.new(self)
    end

    def templates
      @templates ||= Resources::Templates.new(self)
    end

    def phone_numbers
      @phone_numbers ||= Resources::PhoneNumbers.new(self)
    end

    def calls
      @calls ||= Resources::Calls.new(self)
    end

    def conversations
      @conversations ||= Resources::Conversations.new(self)
    end

    def contacts
      @contacts ||= Resources::Contacts.new(self)
    end

    def flows
      @flows ||= Resources::Flows.new(self)
    end

    def kapso_proxy?
      @kapso_proxy
    end

    # Main request method with retry logic and error handling
    def request(method, path, options = {})
      method = method.to_s.upcase
      body = options[:body]
      query = options[:query]
      custom_headers = options[:headers] || {}
      response_type = options[:response_type] || :auto

      url = build_url(path, query)
      headers = build_headers(custom_headers)
      
      # Log request if debugging
      log_request(method, url, headers, body) if debug

      retries = 0
      begin
        response = @http_client.run_request(method.downcase.to_sym, url, body, headers)
        
        # Log response if debugging
        log_response(response) if debug

        # Handle response based on type requested
        handle_response(response, response_type)
      rescue Faraday::Error => e
        retries += 1
        if retries <= max_retries && retryable_error?(e)
          sleep(retry_delay * retries)
          retry
        else
          raise Errors::GraphApiError.new(
            message: "Network error: #{e.message}",
            http_status: 0,
            category: :server
          )
        end
      end
    end

    # Raw HTTP method without automatic error handling (for media downloads, etc.)
    def raw_request(method, url, options = {})
      headers = build_headers(options[:headers] || {})
      
      log_request(method, url, headers, options[:body]) if debug
      
      response = @http_client.run_request(method.to_sym, url, options[:body], headers)
      
      log_response(response) if debug
      
      response
    end

    # Fetch with automatic auth headers (for absolute URLs)
    def fetch(url, options = {})
      headers = build_headers(options[:headers] || {})
      method = options[:method] || 'GET'
      
      log_request(method, url, headers, options[:body]) if debug
      
      response = @http_client.run_request(method.downcase.to_sym, url, options[:body], headers)
      
      log_response(response) if debug
      
      if response.success?
        response
      else
        handle_error_response(response)
      end
    end

    private

    def build_http_client
      Faraday.new do |f|
        f.options.timeout = timeout
        f.options.open_timeout = open_timeout
        f.request :multipart
        f.request :url_encoded
        f.adapter Faraday.default_adapter
      end
    end

    def build_headers(custom_headers = {})
      headers = {}
      
      # Authentication headers
      if access_token
        headers['Authorization'] = "Bearer #{access_token}"
      end
      
      if kapso_api_key
        headers['X-API-Key'] = kapso_api_key
      end
      
      # Default content type for JSON requests
      headers['Content-Type'] = 'application/json' unless custom_headers.key?('Content-Type')
      
      headers.merge(custom_headers.compact)
    end

    def build_url(path, query = nil)
      # Remove leading slash from path
      clean_path = path.to_s.sub(%r{^/}, '')
      
      # Build base URL with version
      base = "#{base_url}/#{graph_version}/"
      full_url = URI.join(base, clean_path).to_s
      
      # Add query parameters if present
      if query && !query.empty?
        # Convert to snake_case for API (Meta expects snake_case)
        snake_query = Types.deep_snake_case_keys(query)
        query_string = URI.encode_www_form(flatten_query(snake_query))
        separator = full_url.include?('?') ? '&' : '?'
        full_url += "#{separator}#{query_string}"
      end
      
      full_url
    end

    def flatten_query(query, prefix = nil)
      result = []
      query.each do |key, value|
        param_key = prefix ? "#{prefix}[#{key}]" : key.to_s
        
        case value
        when Hash
          result.concat(flatten_query(value, param_key))
        when Array
          value.each { |v| result << [param_key, v] }
        else
          result << [param_key, value] unless value.nil?
        end
      end
      result
    end

    def handle_response(response, response_type)
      unless response.success?
        handle_error_response(response)
      end

      case response_type
      when :json
        parse_json_response(response)
      when :raw
        response
      when :auto
        content_type = response.headers['content-type'] || ''
        if content_type.include?('application/json')
          parse_json_response(response)
        elsif response.status == 204
          Types::GraphSuccessResponse.new
        else
          response.body
        end
      else
        response.body
      end
    end

    def parse_json_response(response)
      return Types::GraphSuccessResponse.new if response.body.nil? || response.body.strip.empty?
      
      begin
        json = JSON.parse(response.body)
        # Convert camelCase keys to snake_case for Ruby conventions
        Types.deep_snake_case_keys(json)
      rescue JSON::ParserError => e
        raise Errors::GraphApiError.new(
          message: "Invalid JSON response: #{e.message}",
          http_status: response.status,
          raw_response: response.body
        )
      end
    end

    def handle_error_response(response)
      body = response.body
      
      # Try to parse JSON error
      begin
        json_body = JSON.parse(body) if body && !body.strip.empty?
      rescue JSON::ParserError
        json_body = nil
      end
      
      # Create error with proper parameters
      raise Errors::GraphApiError.from_response(response, json_body || {}, body)
    end

    def retryable_error?(error)
      # Only retry on network errors, not HTTP errors
      error.is_a?(Faraday::TimeoutError) ||
        error.is_a?(Faraday::ConnectionFailed) ||
        error.is_a?(Faraday::ServerError)
    end

    def normalize_base_url(url)
      url = url.to_s
      url = "https://#{url}" unless url.match?(%r{^https?://})
      url.chomp('/')
    end

    def detect_kapso_proxy(url)
      url.match?(KAPSO_PROXY_PATTERN)
    end

    def log_request(method, url, headers, body)
      logger.debug "WhatsApp API Request: #{method} #{url}"
      logger.debug "Headers: #{headers.inspect}" if headers.any?
      
      if body
        if body.is_a?(String)
          logger.debug "Body: #{body.length > 1000 ? "#{body[0..1000]}..." : body}"
        else
          logger.debug "Body: #{body.inspect}"
        end
      end
    end

    def log_response(response)
      logger.debug "WhatsApp API Response: #{response.status}"
      logger.debug "Response Headers: #{response.headers.to_h.inspect}"
      
      if response.body
        body_preview = response.body.length > 1000 ? "#{response.body[0..1000]}..." : response.body
        logger.debug "Response Body: #{body_preview}"
      end
    end
  end
end