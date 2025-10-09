# frozen_string_literal: true

module KapsoClientRuby
  module Resources
    class PhoneNumbers
      def initialize(client)
        @client = client
      end

      # Request verification code
      def request_code(phone_number_id:, code_method:, language: 'en_US')
        validate_code_method(code_method)
        
        payload = {
          code_method: code_method.upcase,
          language: language
        }
        
        response = @client.request(:post, "#{phone_number_id}/request_code", 
                                   body: payload.to_json, response_type: :json)
        Types::GraphSuccessResponse.new(response)
      end

      # Verify the received code
      def verify_code(phone_number_id:, code:)
        raise ArgumentError, 'Verification code cannot be empty' if code.nil? || code.strip.empty?
        
        payload = { code: code.to_s }
        
        response = @client.request(:post, "#{phone_number_id}/verify_code", 
                                   body: payload.to_json, response_type: :json)
        Types::GraphSuccessResponse.new(response)
      end

      # Register phone number
      def register(phone_number_id:, pin:, data_localization_region: nil)
        raise ArgumentError, 'PIN cannot be empty' if pin.nil? || pin.strip.empty?
        
        payload = { pin: pin.to_s }
        payload[:data_localization_region] = data_localization_region if data_localization_region
        
        response = @client.request(:post, "#{phone_number_id}/register", 
                                   body: payload.to_json, response_type: :json)
        Types::GraphSuccessResponse.new(response)
      end

      # Deregister phone number
      def deregister(phone_number_id:)
        response = @client.request(:post, "#{phone_number_id}/deregister", 
                                   body: {}.to_json, response_type: :json)
        Types::GraphSuccessResponse.new(response)
      end

      # Update phone number settings
      def update_settings(phone_number_id:, messaging_product: 'whatsapp', 
                          webhooks: nil, application: nil)
        payload = { messaging_product: messaging_product }
        payload[:webhooks] = webhooks if webhooks
        payload[:application] = application if application
        
        response = @client.request(:post, phone_number_id, 
                                   body: payload.to_json, response_type: :json)
        Types::GraphSuccessResponse.new(response)
      end

      # Get phone number info
      def get(phone_number_id:, fields: nil)
        query_params = {}
        query_params[:fields] = fields if fields
        
        response = @client.request(:get, phone_number_id, 
                                   query: query_params, response_type: :json)
        response
      end

      private

      def validate_code_method(method)
        valid_methods = %w[SMS VOICE]
        unless valid_methods.include?(method.to_s.upcase)
          raise ArgumentError, "Invalid code method '#{method}'. Must be one of: #{valid_methods.join(', ')}"
        end
      end
    end
  end
end