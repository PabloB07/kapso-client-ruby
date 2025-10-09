# frozen_string_literal: true

module KapsoClientRuby
  module Resources
    class Conversations
      def initialize(client)
        @client = client
      end

      # List conversations (Kapso Proxy only)
      def list(phone_number_id:, status: nil, last_active_since: nil, 
               last_active_until: nil, phone_number: nil, limit: nil, 
               after: nil, before: nil, fields: nil)
        assert_kapso_proxy('Conversations API')
        
        query_params = {
          status: status,
          last_active_since: last_active_since,
          last_active_until: last_active_until,
          phone_number: phone_number,
          limit: limit,
          after: after,
          before: before,
          fields: fields
        }.compact
        
        response = @client.request(:get, "#{phone_number_id}/conversations", 
                                   query: query_params, response_type: :json)
        Types::PagedResponse.new(response, Types::ConversationRecord)
      end

      # Get conversation details (Kapso Proxy only)
      def get(conversation_id:)
        assert_kapso_proxy('Conversations API')
        
        raise ArgumentError, 'conversation_id cannot be empty' if conversation_id.nil? || conversation_id.strip.empty?
        
        response = @client.request(:get, "conversations/#{conversation_id}", 
                                   response_type: :json)
        
        # Handle both single object and data envelope responses
        if response.is_a?(Hash) && response.key?('data')
          Types::ConversationRecord.new(response['data'])
        else
          Types::ConversationRecord.new(response)
        end
      end

      # Update conversation status (Kapso Proxy only)
      def update_status(conversation_id:, status:)
        assert_kapso_proxy('Conversations API')
        
        raise ArgumentError, 'conversation_id cannot be empty' if conversation_id.nil? || conversation_id.strip.empty?
        raise ArgumentError, 'status cannot be empty' if status.nil? || status.strip.empty?
        
        payload = { status: status }
        
        response = @client.request(:patch, "conversations/#{conversation_id}", 
                                   body: payload.to_json, response_type: :json)
        Types::GraphSuccessResponse.new(response)
      end

      # Archive conversation (Kapso Proxy only)
      def archive(conversation_id:)
        update_status(conversation_id: conversation_id, status: 'archived')
      end

      # Unarchive conversation (Kapso Proxy only)
      def unarchive(conversation_id:)
        update_status(conversation_id: conversation_id, status: 'active')
      end

      # End conversation (Kapso Proxy only)
      def end_conversation(conversation_id:)
        update_status(conversation_id: conversation_id, status: 'ended')
      end

      # Get conversation analytics (Kapso Proxy only)
      def analytics(phone_number_id:, conversation_id: nil, since: nil, 
                    until_time: nil, granularity: 'day')
        assert_kapso_proxy('Conversation Analytics API')
        
        query_params = {
          conversation_id: conversation_id,
          since: since,
          until: until_time,
          granularity: granularity
        }.compact
        
        response = @client.request(:get, "#{phone_number_id}/conversations/analytics", 
                                   query: query_params, response_type: :json)
        response
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