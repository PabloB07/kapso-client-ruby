# frozen_string_literal: true

require 'mime/types'

module KapsoClientRuby
  module Resources
    class Media
      def initialize(client)
        @client = client
      end

      # Upload media file
      def upload(phone_number_id:, type:, file:, filename: nil, messaging_product: 'whatsapp', 
                 upload_strategy: nil)
        validate_media_type(type)
        
        # Build multipart form data
        form_data = {
          'messaging_product' => messaging_product,
          'type' => type
        }
        
        # Handle file parameter - can be File, IO, or file path string
        file_obj = case file
                   when String
                     # Assume it's a file path
                     File.open(file, 'rb')
                   when File, IO, StringIO
                     file
                   else
                     raise ArgumentError, 'file must be a File, IO object, or file path string'
                   end
        
        # Determine filename and content type
        if filename.nil? && file.is_a?(String)
          filename = File.basename(file)
        end
        
        content_type = determine_content_type(file_obj, filename, type)
        
        form_data['file'] = Faraday::UploadIO.new(file_obj, content_type, filename)
        form_data['upload_strategy'] = upload_strategy if upload_strategy
        
        # Set multipart content type header
        headers = { 'Content-Type' => 'multipart/form-data' }
        
        response = @client.request(:post, "#{phone_number_id}/media", 
                                   body: form_data, headers: headers, response_type: :json)
        
        # Close file if we opened it
        file_obj.close if file.is_a?(String) && file_obj.respond_to?(:close)
        
        Types::MediaUploadResponse.new(response)
      end

      # Get media metadata
      def get(media_id:, phone_number_id: nil)
        # phone_number_id is required for Kapso proxy
        if @client.kapso_proxy? && phone_number_id.nil?
          raise ArgumentError, 'phone_number_id is required when using Kapso proxy'
        end
        
        query_params = {}
        query_params[:phone_number_id] = phone_number_id if phone_number_id
        
        response = @client.request(:get, media_id, 
                                   query: query_params, response_type: :json)
        Types::MediaMetadataResponse.new(response)
      end

      # Delete media
      def delete(media_id:, phone_number_id: nil)
        # phone_number_id is required for Kapso proxy
        if @client.kapso_proxy? && phone_number_id.nil?
          raise ArgumentError, 'phone_number_id is required when using Kapso proxy'
        end
        
        query_params = {}
        query_params[:phone_number_id] = phone_number_id if phone_number_id
        
        response = @client.request(:delete, media_id, 
                                   query: query_params, response_type: :json)
        Types::GraphSuccessResponse.new(response)
      end

      # Download media content
      def download(media_id:, phone_number_id: nil, headers: {}, 
                   auth: :auto, as: :binary)
        # First get the media metadata to get the download URL
        metadata = get(media_id: media_id, phone_number_id: phone_number_id)
        download_url = metadata.url
        
        # Determine authentication strategy
        use_auth = case auth
                   when :auto
                     # Auto-detect: use auth for graph.facebook.com URLs, no auth for CDNs
                     download_url.include?('graph.facebook.com')
                   when :always
                     true
                   when :never
                     false
                   else
                     raise ArgumentError, 'auth must be :auto, :always, or :never'
                   end
        
        # Prepare headers
        download_headers = headers.dup
        
        # Make the download request
        if use_auth
          response = @client.fetch(download_url, headers: download_headers)
        else
          response = @client.raw_request(:get, download_url, headers: download_headers)
        end
        
        unless response.success?
          raise Errors::GraphApiError.new(
            message: "Failed to download media: #{response.status}",
            http_status: response.status,
            raw_response: response.body
          )
        end
        
        # Return response based on requested format
        case as
        when :binary
          response.body
        when :response
          response
        when :base64
          require 'base64'
          Base64.strict_encode64(response.body)
        else
          raise ArgumentError, 'as must be :binary, :response, or :base64'
        end
      end

      # Save media to file
      def save_to_file(media_id:, filepath:, phone_number_id: nil, headers: {}, auth: :auto)
        content = download(
          media_id: media_id, 
          phone_number_id: phone_number_id,
          headers: headers,
          auth: auth,
          as: :binary
        )
        
        File.binwrite(filepath, content)
        filepath
      end

      # Get media info including size, type, and download URL
      def info(media_id:, phone_number_id: nil)
        metadata = get(media_id: media_id, phone_number_id: phone_number_id)
        
        {
          id: metadata.id,
          url: metadata.url,
          mime_type: metadata.mime_type,
          sha256: metadata.sha256,
          file_size: metadata.file_size.to_i,
          messaging_product: metadata.messaging_product
        }
      end

      private

      def validate_media_type(type)
        valid_types = %w[image audio video document sticker]
        unless valid_types.include?(type.to_s)
          raise ArgumentError, "Invalid media type '#{type}'. Must be one of: #{valid_types.join(', ')}"
        end
      end

      def determine_content_type(file_obj, filename, media_type)
        # First try to determine from filename
        if filename
          mime_types = MIME::Types.type_for(filename)
          return mime_types.first.content_type unless mime_types.empty?
        end
        
        # Try to determine from file extension if file_obj responds to path
        if file_obj.respond_to?(:path) && file_obj.path
          mime_types = MIME::Types.type_for(file_obj.path)
          return mime_types.first.content_type unless mime_types.empty?
        end
        
        # Fall back to generic types based on media_type
        case media_type.to_s
        when 'image'
          'image/jpeg'
        when 'audio'
          'audio/mpeg'
        when 'video'
          'video/mp4'
        when 'document'
          'application/pdf'
        when 'sticker'
          'image/webp'
        else
          'application/octet-stream'
        end
      end
    end
  end
end