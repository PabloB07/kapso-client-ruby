# frozen_string_literal: true

module KapsoClientRuby
  module Resources
    class Calls
      def initialize(client)
        @client = client
      end

      # Initiate a call
      def connect(phone_number_id:, to:, session: nil, biz_opaque_callback_data: nil)
        payload = {
          messaging_product: 'whatsapp',
          to: to,
          action: 'connect'
        }
        
        payload[:session] = session if session
        payload[:biz_opaque_callback_data] = biz_opaque_callback_data if biz_opaque_callback_data
        
        response = @client.request(:post, "#{phone_number_id}/calls", 
                                   body: payload.to_json, response_type: :json)
        Types::CallConnectResponse.new(response)
      end

      # Pre-accept a call
      def pre_accept(phone_number_id:, call_id:, session:)
        raise ArgumentError, 'call_id cannot be empty' if call_id.nil? || call_id.strip.empty?
        raise ArgumentError, 'session cannot be nil' if session.nil?
        
        payload = {
          messaging_product: 'whatsapp',
          call_id: call_id,
          action: 'pre_accept',
          session: session
        }
        
        response = @client.request(:post, "#{phone_number_id}/calls", 
                                   body: payload.to_json, response_type: :json)
        Types::CallActionResponse.new(response)
      end

      # Accept a call
      def accept(phone_number_id:, call_id:, session:, biz_opaque_callback_data: nil)
        raise ArgumentError, 'call_id cannot be empty' if call_id.nil? || call_id.strip.empty?
        raise ArgumentError, 'session cannot be nil' if session.nil?
        
        payload = {
          messaging_product: 'whatsapp',
          call_id: call_id,
          action: 'accept',
          session: session
        }
        
        payload[:biz_opaque_callback_data] = biz_opaque_callback_data if biz_opaque_callback_data
        
        response = @client.request(:post, "#{phone_number_id}/calls", 
                                   body: payload.to_json, response_type: :json)
        Types::CallActionResponse.new(response)
      end

      # Reject a call
      def reject(phone_number_id:, call_id:)
        raise ArgumentError, 'call_id cannot be empty' if call_id.nil? || call_id.strip.empty?
        
        payload = {
          messaging_product: 'whatsapp',
          call_id: call_id,
          action: 'reject'
        }
        
        response = @client.request(:post, "#{phone_number_id}/calls", 
                                   body: payload.to_json, response_type: :json)
        Types::CallActionResponse.new(response)
      end

      # Terminate a call
      def terminate(phone_number_id:, call_id:)
        raise ArgumentError, 'call_id cannot be empty' if call_id.nil? || call_id.strip.empty?
        
        payload = {
          messaging_product: 'whatsapp',
          call_id: call_id,
          action: 'terminate'
        }
        
        response = @client.request(:post, "#{phone_number_id}/calls", 
                                   body: payload.to_json, response_type: :json)
        Types::CallActionResponse.new(response)
      end

      # List calls (Kapso Proxy only)
      def list(phone_number_id:, direction: nil, status: nil, since: nil, 
               until_time: nil, call_id: nil, limit: nil, after: nil, 
               before: nil, fields: nil)
        assert_kapso_proxy('Call history API')
        
        query_params = {
          direction: direction,
          status: status,
          since: since,
          until: until_time,
          call_id: call_id,
          limit: limit,
          after: after,
          before: before,
          fields: fields
        }.compact
        
        response = @client.request(:get, "#{phone_number_id}/calls", 
                                   query: query_params, response_type: :json)
        Types::PagedResponse.new(response, Types::CallRecord)
      end

      # Get call details (Kapso Proxy only)
      def get(phone_number_id:, call_id:, fields: nil)
        assert_kapso_proxy('Call details API')
        
        query_params = {}
        query_params[:fields] = fields if fields
        
        response = @client.request(:get, "#{phone_number_id}/calls/#{call_id}", 
                                   query: query_params, response_type: :json)
        Types::CallRecord.new(response)
      end

      # Call permissions management
      class Permissions
        def initialize(client)
          @client = client
        end

        # Get call permissions
        def get(phone_number_id:, user_wa_id:)
          raise ArgumentError, 'user_wa_id cannot be empty' if user_wa_id.nil? || user_wa_id.strip.empty?
          
          query_params = { user_wa_id: user_wa_id }
          
          response = @client.request(:get, "#{phone_number_id}/call_permissions", 
                                     query: query_params, response_type: :json)
          response
        end

        # Update call permissions
        def update(phone_number_id:, user_wa_id:, permission:)
          raise ArgumentError, 'user_wa_id cannot be empty' if user_wa_id.nil? || user_wa_id.strip.empty?
          raise ArgumentError, 'permission cannot be empty' if permission.nil?
          
          payload = {
            user_wa_id: user_wa_id,
            permission: permission
          }
          
          response = @client.request(:post, "#{phone_number_id}/call_permissions", 
                                     body: payload.to_json, response_type: :json)
          Types::GraphSuccessResponse.new(response)
        end
      end

      def permissions
        @permissions ||= Permissions.new(@client)
      end

      private

      def assert_kapso_proxy(feature)
        unless @client.kapso_proxy?
          raise Errors::KapsoProxyRequiredError.new(feature)
        end
      end
    end
  end
end