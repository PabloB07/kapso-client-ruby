# frozen_string_literal: true

module KapsoClientRuby
  module Resources
    class Contacts
      def initialize(client)
        @client = client
      end

      # List contacts (Kapso Proxy only)
      def list(phone_number_id:, customer_id: nil, phone_number: nil, 
               profile_name: nil, limit: nil, after: nil, before: nil, fields: nil)
        assert_kapso_proxy('Contacts API')
        
        query_params = {
          customer_id: customer_id,
          phone_number: phone_number,
          profile_name: profile_name,
          limit: limit,
          after: after,
          before: before,
          fields: fields
        }.compact
        
        response = @client.request(:get, "#{phone_number_id}/contacts", 
                                   query: query_params, response_type: :json)
        Types::PagedResponse.new(response, Types::ContactRecord)
      end

      # Get contact details (Kapso Proxy only)
      def get(phone_number_id:, wa_id:, fields: nil)
        assert_kapso_proxy('Contacts API')
        
        raise ArgumentError, 'wa_id cannot be empty' if wa_id.nil? || wa_id.strip.empty?
        
        query_params = {}
        query_params[:fields] = fields if fields
        
        response = @client.request(:get, "#{phone_number_id}/contacts/#{wa_id}", 
                                   query: query_params, response_type: :json)
        
        # Handle both single object and data envelope responses
        if response.is_a?(Hash) && response.key?('data')
          Types::ContactRecord.new(response['data'])
        else
          Types::ContactRecord.new(response)
        end
      end

      # Update contact metadata (Kapso Proxy only)
      def update(phone_number_id:, wa_id:, metadata: nil, tags: nil, 
                 customer_id: nil, notes: nil)
        assert_kapso_proxy('Contacts API')
        
        raise ArgumentError, 'wa_id cannot be empty' if wa_id.nil? || wa_id.strip.empty?
        
        payload = {}
        payload[:metadata] = metadata if metadata
        payload[:tags] = tags if tags
        payload[:customer_id] = customer_id if customer_id
        payload[:notes] = notes if notes
        
        return if payload.empty?
        
        response = @client.request(:patch, "#{phone_number_id}/contacts/#{wa_id}", 
                                   body: payload.to_json, response_type: :json)
        Types::GraphSuccessResponse.new(response)
      end

      # Add tags to contact (Kapso Proxy only)
      def add_tags(phone_number_id:, wa_id:, tags:)
        raise ArgumentError, 'tags cannot be empty' if tags.nil? || tags.empty?
        
        current_contact = get(phone_number_id: phone_number_id, wa_id: wa_id)
        existing_tags = (current_contact.metadata&.[]('tags') || [])
        new_tags = (existing_tags + Array(tags)).uniq
        
        update(phone_number_id: phone_number_id, wa_id: wa_id, 
               metadata: { tags: new_tags })
      end

      # Remove tags from contact (Kapso Proxy only)
      def remove_tags(phone_number_id:, wa_id:, tags:)
        raise ArgumentError, 'tags cannot be empty' if tags.nil? || tags.empty?
        
        current_contact = get(phone_number_id: phone_number_id, wa_id: wa_id)
        existing_tags = (current_contact.metadata&.[]('tags') || [])
        remaining_tags = existing_tags - Array(tags)
        
        update(phone_number_id: phone_number_id, wa_id: wa_id, 
               metadata: { tags: remaining_tags })
      end

      # Search contacts by various criteria (Kapso Proxy only)
      def search(phone_number_id:, query:, search_in: ['profile_name', 'phone_number'], 
                 limit: nil, after: nil, before: nil)
        assert_kapso_proxy('Contacts Search API')
        
        raise ArgumentError, 'query cannot be empty' if query.nil? || query.strip.empty?
        
        query_params = {
          q: query,
          search_in: Array(search_in).join(','),
          limit: limit,
          after: after,
          before: before
        }.compact
        
        response = @client.request(:get, "#{phone_number_id}/contacts/search", 
                                   query: query_params, response_type: :json)
        Types::PagedResponse.new(response, Types::ContactRecord)
      end

      # Get contact analytics (Kapso Proxy only)
      def analytics(phone_number_id:, wa_id: nil, since: nil, until_time: nil, 
                    granularity: 'day', metrics: nil)
        assert_kapso_proxy('Contact Analytics API')
        
        query_params = {
          wa_id: wa_id,
          since: since,
          until: until_time,
          granularity: granularity
        }
        query_params[:metrics] = Array(metrics).join(',') if metrics
        query_params = query_params.compact
        
        response = @client.request(:get, "#{phone_number_id}/contacts/analytics", 
                                   query: query_params, response_type: :json)
        response
      end

      # Export contacts (Kapso Proxy only)
      def export(phone_number_id:, format: 'csv', filters: nil)
        assert_kapso_proxy('Contacts Export API')
        
        payload = {
          format: format,
          filters: filters
        }.compact
        
        response = @client.request(:post, "#{phone_number_id}/contacts/export", 
                                   body: payload.to_json, response_type: :json)
        response
      end

      # Import contacts (Kapso Proxy only)
      def import(phone_number_id:, file:, format: 'csv', mapping: nil, 
                 duplicate_handling: 'skip')
        assert_kapso_proxy('Contacts Import API')
        
        # Build multipart form data
        form_data = {
          'format' => format,
          'duplicate_handling' => duplicate_handling
        }
        
        # Handle file parameter
        file_obj = case file
                   when String
                     File.open(file, 'rb')
                   when File, IO, StringIO
                     file
                   else
                     raise ArgumentError, 'file must be a File, IO object, or file path string'
                   end
        
        form_data['file'] = Faraday::UploadIO.new(file_obj, 'text/csv', 'contacts.csv')
        form_data['mapping'] = mapping.to_json if mapping
        
        headers = { 'Content-Type' => 'multipart/form-data' }
        
        response = @client.request(:post, "#{phone_number_id}/contacts/import", 
                                   body: form_data, headers: headers, response_type: :json)
        
        # Close file if we opened it
        file_obj.close if file.is_a?(String) && file_obj.respond_to?(:close)
        
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