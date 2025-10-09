# frozen_string_literal: true

module KapsoClientRuby
  module Errors
    # Error categories mapped from the JavaScript implementation
    ERROR_CATEGORIES = {
      'authorization' => :authorization,
      'permission' => :permission,
      'parameter' => :parameter,
      'throttling' => :throttling,
      'template' => :template,
      'media' => :media,
      'phone_registration' => :phone_registration,
      'integrity' => :integrity,
      'business_eligibility' => :business_eligibility,
      'reengagement_window' => :reengagement_window,
      'waba_config' => :waba_config,
      'flow' => :flow,
      'synchronization' => :synchronization,
      'server' => :server,
      'unknown' => :unknown
    }.freeze

    # Error codes and their categories
    ERROR_CODE_CATEGORIES = {
      0 => :authorization,
      190 => :authorization,
      3 => :permission,
      10 => :permission,
      (200..219) => :permission,
      4 => :throttling,
      80007 => :throttling,
      130429 => :throttling,
      131048 => :throttling,
      131056 => :throttling,
      33 => :parameter,
      100 => :parameter,
      130472 => :parameter,
      131008 => :parameter,
      131009 => :parameter,
      131021 => :parameter,
      131026 => :parameter,
      131051 => :media,
      131052 => :media,
      131053 => :media,
      131000 => :server,
      131016 => :server,
      131057 => :server,
      133004 => :server,
      133005 => :server,
      368 => :integrity,
      130497 => :integrity,
      131031 => :integrity,
      131047 => :reengagement_window,
      131037 => :waba_config,
      131042 => :business_eligibility,
      131045 => :phone_registration,
      133000 => :phone_registration,
      133006 => :phone_registration,
      133008 => :phone_registration,
      133009 => :phone_registration,
      133010 => :phone_registration,
      133015 => :phone_registration,
      133016 => :phone_registration,
      132000 => :template,
      132001 => :template,
      132005 => :template,
      132007 => :template,
      132012 => :template,
      132015 => :template,
      132016 => :template,
      132068 => :flow,
      132069 => :flow,
      134011 => :business_eligibility,
      135000 => :parameter,
      2593107 => :synchronization,
      2593108 => :synchronization
    }.freeze

    # Error codes that should not be retried
    DO_NOT_RETRY_CODES = [131049, 131050, 131047, 368, 130497, 131031].freeze

    # Error codes that require token refresh
    REFRESH_TOKEN_CODES = [0, 190].freeze

    class GraphApiError < StandardError
      attr_reader :http_status, :code, :type, :details, :error_subcode, 
                  :fbtrace_id, :error_data, :category, :retry_hint, :raw_response, :retry_after

      def initialize(message: nil, http_status:, code: nil, type: nil, details: nil, 
                     error_subcode: nil, fbtrace_id: nil, error_data: nil, 
                     category: nil, retry_hint: nil, raw_response: nil, retry_after: nil)
        @http_status = http_status
        @code = code || http_status
        @type = type || 'GraphApiError'
        @details = details
        @error_subcode = error_subcode
        @fbtrace_id = fbtrace_id
        @error_data = error_data
        @retry_after = retry_after
        @category = category || categorize_error_code(@code, @http_status)
        @retry_hint = retry_hint || derive_retry_hint
        @raw_response = raw_response

        error_message = message || build_error_message
        super(error_message)
      end

      class << self
        def from_response(response, body = nil, raw_text = nil)
          http_status = response.status
          retry_after_ms = parse_retry_after(response.headers['retry-after'])

          # Ensure body is a hash for processing
          unless body.is_a?(Hash)
            if body.is_a?(String)
              begin
                body = JSON.parse(body)
              rescue JSON::ParserError
                body = {}
              end
            else
              body = {}
            end
          end

          # Check for Graph API error envelope
          if body.key?('error')
            error_payload = body['error']
            code = error_payload['code'] || http_status
            type = error_payload['type'] || 'GraphApiError'
            details = error_payload.is_a?(Hash) ? error_payload.dig('error_data', 'details') : nil
            
            new(
              message: error_payload['message'],
              http_status: http_status,
              code: code,
              type: type,
              details: details,
              error_subcode: error_payload['error_subcode'],
              fbtrace_id: error_payload['fbtrace_id'],
              error_data: error_payload['error_data'],
              retry_hint: build_retry_hint_with_delay(code, http_status, retry_after_ms),
              raw_response: body
            )
          elsif body.is_a?(Hash) && body.key?('error') && body['error'].is_a?(String)
            # Kapso proxy error format
            category = http_status >= 500 ? :server : categorize_error_code(nil, http_status)
            new(
              message: body['error'],
              http_status: http_status,
              code: http_status,
              category: category,
              retry_hint: build_retry_hint_with_delay(http_status, http_status, retry_after_ms),
              raw_response: body
            )
          else
            # Generic HTTP error
            category = http_status >= 500 ? :server : categorize_error_code(nil, http_status)
            message = build_default_message(http_status, nil, raw_text)
            
            new(
              message: message,
              http_status: http_status,
              code: http_status,
              category: category,
              retry_hint: build_retry_hint_with_delay(http_status, http_status, retry_after_ms),
              raw_response: raw_text || body
            )
          end
        end

        private

        def parse_retry_after(header)
          return nil unless header

          # Try parsing as number of seconds
          if header.match?(/^\d+$/)
            header.to_i * 1000
          else
            # Try parsing as HTTP date
            begin
              date = Time.parse(header)
              diff = (date.to_f - Time.now.to_f) * 1000
              diff > 0 ? diff.to_i : 0
            rescue ArgumentError
              nil
            end
          end
        end

        def categorize_error_code(code, http_status)
          return :authorization if http_status == 401
          return :permission if http_status == 403
          return :parameter if http_status == 404
          return :throttling if http_status == 429
          return :server if http_status >= 500
          return :parameter if http_status >= 400 && http_status < 500

          if code
            ERROR_CODE_CATEGORIES.each do |key, category|
              if key.is_a?(Range)
                return category if key.include?(code)
              elsif key == code
                return category
              end
            end

            # Check permission range
            return :permission if code >= 200 && code <= 299
          end

          :unknown
        end

        def build_retry_hint_with_delay(code, http_status, retry_after_ms)
          if retry_after_ms
            { action: :retry_after, retry_after_ms: retry_after_ms }
          elsif DO_NOT_RETRY_CODES.include?(code)
            { action: :do_not_retry }
          elsif REFRESH_TOKEN_CODES.include?(code)
            { action: :refresh_token }
          elsif http_status >= 500
            { action: :retry }
          else
            { action: :fix_and_retry }
          end
        end

        def build_default_message(status, details = nil, raw_text = nil)
          if details
            "Meta API request failed with status #{status}: #{details}"
          elsif raw_text && !raw_text.strip.empty?
            "Meta API request failed with status #{status}: #{raw_text}"
          else
            "Meta API request failed with status #{status}"
          end
        end
      end

      def auth_error?
        category == :authorization
      end

      def rate_limit?
        category == :throttling
      end

      def temporary?
        [:throttling, :server, :synchronization].include?(category) || 
        http_status >= 500 || 
        [1, 2, 17, 341].include?(code)
      end

      def template_error?
        category == :template
      end

      def requires_token_refresh?
        category == :authorization || REFRESH_TOKEN_CODES.include?(code)
      end

      def retryable?
        ![:do_not_retry].include?(retry_hint[:action])
      end

      def to_h
        {
          name: self.class.name,
          message: message,
          http_status: http_status,
          code: code,
          type: type,
          details: details,
          error_subcode: error_subcode,
          fbtrace_id: fbtrace_id,
          category: category,
          retry_hint: retry_hint,
          raw_response: raw_response
        }
      end

      private

      def categorize_error_code(code, http_status)
        self.class.send(:categorize_error_code, code, http_status)
      end

      def derive_retry_hint
        if DO_NOT_RETRY_CODES.include?(code)
          { action: :do_not_retry }
        elsif REFRESH_TOKEN_CODES.include?(code)
          { action: :refresh_token }
        elsif http_status >= 500
          { action: :retry }
        else
          { action: :fix_and_retry }
        end
      end

      def build_error_message
        if details
          "Meta API request failed with status #{http_status}: #{details}"
        elsif raw_response.is_a?(String) && !raw_response.strip.empty?
          "Meta API request failed with status #{http_status}: #{raw_response}"
        else
          "Meta API request failed with status #{http_status}"
        end
      end
    end

    class KapsoProxyRequiredError < StandardError
      attr_reader :feature, :help_url

      def initialize(feature)
        @feature = feature
        @help_url = 'https://kapso.ai/'
        
        message = "#{feature} is only available via the Kapso Proxy. " \
                  "Set base_url to https://app.kapso.ai/api/meta and provide kapso_api_key. " \
                  "Create a free account at #{help_url}"
        super(message)
      end
    end

    class ConfigurationError < StandardError; end
    class ValidationError < StandardError; end
  end
end