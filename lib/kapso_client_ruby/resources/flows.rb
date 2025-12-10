# frozen_string_literal: true

require 'openssl'
require 'base64'
require 'json'

module KapsoClientRuby
  module Resources
    # Manages WhatsApp Flows - interactive forms and data collection
    # Flows allow you to build rich, multi-step experiences within WhatsApp
    class Flows
      def initialize(client)
        @client = client
      end

      # Create a new Flow
      # @param business_account_id [String] WhatsApp Business Account ID
      # @param name [String] Flow name
      # @param categories [Array<String>] Flow categories (e.g., ['APPOINTMENT_BOOKING'])
      # @param options [Hash] Additional options
      # @option options [String] :endpoint_uri Data endpoint URL for Flow callbacks
      # @option options [String] :application_id Application ID for the Flow
      # @return [Hash] Created Flow data with ID
      def create(business_account_id:, name:, categories: ['OTHER'], **options)
        payload = {
          name: name,
          categories: categories
        }
        
        payload[:endpoint_uri] = options[:endpoint_uri] if options[:endpoint_uri]
        payload[:application_id] = options[:application_id] if options[:application_id]
        
        response = @client.request(
          :post,
          "#{business_account_id}/flows",
          body: payload.to_json,
          response_type: :json
        )
        
        Types::FlowResponse.new(response)
      end

      # Update an existing Flow
      # @param flow_id [String] Flow ID
      # @param attributes [Hash] Attributes to update (name, categories, endpoint_uri, application_id)
      # @return [Hash] Updated Flow data
      def update(flow_id:, **attributes)
        valid_attributes = [:name, :categories, :endpoint_uri, :application_id]
        payload = attributes.select { |k, _| valid_attributes.include?(k) }
        
        raise ArgumentError, 'No valid attributes provided' if payload.empty?
        
        response = @client.request(
          :post,
          "#{flow_id}",
          body: payload.to_json,
          response_type: :json
        )
        
        Types::FlowResponse.new(response)
      end

      # Delete a Flow
      # @param flow_id [String] Flow ID
      # @return [Hash] Success response
      def delete(flow_id:)
        response = @client.request(
          :delete,
          "#{flow_id}",
          response_type: :json
        )
        
        Types::GraphSuccessResponse.new(response)
      end

      # Get Flow details
      # @param flow_id [String] Flow ID
      # @param fields [Array<String>, nil] Specific fields to retrieve
      # @return [Hash] Flow data
      def get(flow_id:, fields: nil)
        query_params = {}
        query_params[:fields] = fields.join(',') if fields
        
        response = @client.request(
          :get,
          "#{flow_id}",
          query: query_params,
          response_type: :json
        )
        
        Types::FlowData.new(response)
      end

      # List all Flows for a business account
      # @param business_account_id [String] WhatsApp Business Account ID
      # @param fields [Array<String>, nil] Specific fields to retrieve
      # @return [Hash] List of Flows
      def list(business_account_id:, fields: nil)
        query_params = {}
        query_params[:fields] = fields.join(',') if fields
        
        response = @client.request(
          :get,
          "#{business_account_id}/flows",
          query: query_params,
          response_type: :json
        )
        
        Types::PagedResponse.new(response)
      end

      # Publish a Flow
      # @param flow_id [String] Flow ID
      # @param phone_number_id [String, nil] Phone number ID (for query params)
      # @param business_account_id [String, nil] Business account ID (for query params)
      # @return [Hash] Success response
      def publish(flow_id:, phone_number_id: nil, business_account_id: nil)
        query_params = build_query_params(phone_number_id, business_account_id)
        
        response = @client.request(
          :post,
          "#{flow_id}/publish",
          query: query_params,
          body: {}.to_json,
          response_type: :json
        )
        
        Types::GraphSuccessResponse.new(response)
      end

      # Deprecate a Flow
      # @param flow_id [String] Flow ID
      # @param phone_number_id [String, nil] Phone number ID (for query params)
      # @param business_account_id [String, nil] Business account ID (for query params)
      # @return [Hash] Success response
      def deprecate(flow_id:, phone_number_id: nil, business_account_id: nil)
        query_params = build_query_params(phone_number_id, business_account_id)
        
        response = @client.request(
          :post,
          "#{flow_id}/deprecate",
          query: query_params,
          body: {}.to_json,
          response_type: :json
        )
        
        Types::GraphSuccessResponse.new(response)
      end

      # Update Flow asset (JSON definition)
      # @param flow_id [String] Flow ID
      # @param asset [Hash, String] Flow JSON definition (Hash or JSON string)
      # @param phone_number_id [String, nil] Phone number ID (for query params)
      # @param business_account_id [String, nil] Business account ID (for query params)
      # @return [Hash] Asset update response with validation results
      def update_asset(flow_id:, asset:, phone_number_id: nil, business_account_id: nil)
        query_params = build_query_params(phone_number_id, business_account_id)
        
        # Convert asset to JSON string if it's a Hash
        asset_json = asset.is_a?(String) ? asset : asset.to_json
        
        # Create multipart form data
        payload = {
          messaging_product: 'whatsapp',
          asset_type: 'FLOW_JSON',
          asset: asset_json
        }
        
        response = @client.request(
          :post,
          "#{flow_id}/assets",
          query: query_params,
          body: payload.to_json,
          response_type: :json
        )
        
        Types::FlowAssetResponse.new(response)
      end

      # Get Flow preview URL
      # @param flow_id [String] Flow ID
      # @param phone_number_id [String, nil] Phone number ID (for query params)
      # @param business_account_id [String, nil] Business account ID (for query params)
      # @return [Hash] Preview URL response
      def preview(flow_id:, phone_number_id: nil, business_account_id: nil)
        query_params = build_query_params(phone_number_id, business_account_id)
        query_params[:fields] = 'preview.preview_url,preview.expires_at'
        
        response = @client.request(
          :get,
          "#{flow_id}",
          query: query_params,
          response_type: :json
        )
        
        Types::FlowPreviewResponse.new(response)
      end

      # Idempotent Flow deployment - creates or updates, then publishes
      # @param business_account_id [String] WhatsApp Business Account ID
      # @param name [String] Flow name
      # @param flow_json [Hash] Flow JSON definition
      # @param categories [Array<String>] Flow categories
      # @param endpoint_uri [String, nil] Data endpoint URL
      # @param application_id [String, nil] Application ID
      # @return [Hash] Deployment result with flow ID and status
      def deploy(business_account_id:, name:, flow_json:, categories: ['OTHER'],
                 endpoint_uri: nil, application_id: nil)
        # Check if flow exists by name
        existing_flows = list(business_account_id: business_account_id)
        flow = existing_flows.dig('data')&.find { |f| f['name'] == name }
        
        if flow.nil?
          # Create new flow
          @client.logger.debug "Creating new Flow: #{name}"
          created = create(
            business_account_id: business_account_id,
            name: name,
            categories: categories,
            endpoint_uri: endpoint_uri,
            application_id: application_id
          )
          flow_id = created['id']
        else
          # Use existing flow
          flow_id = flow['id']
          @client.logger.debug "Using existing Flow: #{name} (#{flow_id})"
          
          # Update attributes if provided
          update_attrs = {}
          update_attrs[:categories] = categories if categories != ['OTHER']
          update_attrs[:endpoint_uri] = endpoint_uri if endpoint_uri
          update_attrs[:application_id] = application_id if application_id
          
          unless update_attrs.empty?
            update(flow_id: flow_id, **update_attrs)
          end
        end
        
        # Update asset
        @client.logger.debug "Updating Flow asset for #{flow_id}"
        update_asset(flow_id: flow_id, asset: flow_json)
        
        # Publish
        @client.logger.debug "Publishing Flow #{flow_id}"
        publish(flow_id: flow_id)
        
        {
          id: flow_id,
          name: name,
          status: 'published',
          message: flow.nil? ? 'Flow created and published' : 'Flow updated and published'
        }
      end

      # Receive and decrypt Flow event from webhook
      # @param encrypted_request [String] Encrypted request body from webhook
      # @param private_key [String, OpenSSL::PKey::RSA] Private key for decryption (PEM format or key object)
      # @param passphrase [String, nil] Passphrase for encrypted private key
      # @return [Hash] Decrypted Flow event data
      def receive_flow_event(encrypted_request:, private_key:, passphrase: nil)
        # Parse encrypted request
        request_data = JSON.parse(encrypted_request)
        
        # Extract encrypted components
        encrypted_aes_key = Base64.decode64(request_data['encrypted_aes_key'])
        encrypted_flow_data = Base64.decode64(request_data['encrypted_flow_data'])
        initial_vector = Base64.decode64(request_data['initial_vector'])
        
        # Load private key if it's a string
        rsa_key = if private_key.is_a?(String)
                    OpenSSL::PKey::RSA.new(private_key, passphrase)
                  else
                    private_key
                  end
        
        # Decrypt AES key using RSA private key
        aes_key = rsa_key.private_decrypt(encrypted_aes_key)
        
        # Decrypt flow data using AES
        cipher = OpenSSL::Cipher.new('AES-128-GCM')
        cipher.decrypt
        cipher.key = aes_key
        cipher.iv = initial_vector
        
        # Extract authentication tag (last 16 bytes)
        auth_tag = encrypted_flow_data[-16..]
        ciphertext = encrypted_flow_data[0...-16]
        cipher.auth_tag = auth_tag
        
        decrypted_data = cipher.update(ciphertext) + cipher.final
        
        # Parse and return decrypted JSON
        flow_event = JSON.parse(decrypted_data)
        Types::FlowEventData.new(flow_event)
      rescue OpenSSL::PKey::RSAError => e
        raise Errors::FlowDecryptionError.new("Failed to decrypt with private key: #{e.message}")
      rescue OpenSSL::Cipher::CipherError => e
        raise Errors::FlowDecryptionError.new("Failed to decrypt flow data: #{e.message}")
      rescue JSON::ParserError => e
        raise Errors::FlowDecryptionError.new("Invalid JSON in encrypted request: #{e.message}")
      end

      # Encrypt and send response to Flow
      # @param response_data [Hash] Response data to send to Flow
      # @param private_key [String, OpenSSL::PKey::RSA] Private key for signing (PEM format or key object)
      # @param passphrase [String, nil] Passphrase for encrypted private key
      # @return [String] Encrypted response JSON
      def respond_to_flow(response_data:, private_key:, passphrase: nil)
        # Load private key if it's a string
        rsa_key = if private_key.is_a?(String)
                    OpenSSL::PKey::RSA.new(private_key, passphrase)
                  else
                    private_key
                  end
        
        # Generate random AES key and IV
        aes_key = OpenSSL::Cipher.new('AES-128-GCM').random_key
        initial_vector = OpenSSL::Cipher.new('AES-128-GCM').random_iv
        
        # Encrypt response data using AES
        cipher = OpenSSL::Cipher.new('AES-128-GCM')
        cipher.encrypt
        cipher.key = aes_key
        cipher.iv = initial_vector
        
        response_json = response_data.to_json
        encrypted_data = cipher.update(response_json) + cipher.final
        auth_tag = cipher.auth_tag
        
        # Combine ciphertext and auth tag
        encrypted_flow_data = encrypted_data + auth_tag
        
        # Encrypt AES key using RSA public key
        encrypted_aes_key = rsa_key.public_encrypt(aes_key)
        
        # Build encrypted response
        encrypted_response = {
          encrypted_aes_key: Base64.encode64(encrypted_aes_key),
          encrypted_flow_data: Base64.encode64(encrypted_flow_data),
          initial_vector: Base64.encode64(initial_vector)
        }
        
        encrypted_response.to_json
      rescue OpenSSL::PKey::RSAError => e
        raise Errors::FlowEncryptionError.new("Failed to encrypt with private key: #{e.message}")
      rescue OpenSSL::Cipher::CipherError => e
        raise Errors::FlowEncryptionError.new("Failed to encrypt flow response: #{e.message}")
      end

      # Download media from Flow
      # @param media_url [String] Media URL from Flow event
      # @param access_token [String, nil] Access token (uses client token if not provided)
      # @return [String] Binary media content
      def download_flow_media(media_url:, access_token: nil)
        token = access_token || @client.access_token
        
        unless token
          raise Errors::ConfigurationError, 'Access token required to download Flow media'
        end
        
        # Make authenticated request to media URL
        response = @client.fetch(
          media_url,
          headers: { 'Authorization' => "Bearer #{token}" }
        )
        
        response.body
      end

      private

      # Build query parameters for Flow operations
      def build_query_params(phone_number_id, business_account_id)
        params = {}
        params[:phone_number_id] = phone_number_id if phone_number_id
        params[:business_account_id] = business_account_id if business_account_id
        params
      end
    end
  end
end
