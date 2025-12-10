# frozen_string_literal: true

module KapsoClientRuby
  module Resources
    class Messages
      def initialize(client)
        @client = client
      end

      # Text Messages
      # @param recipient_type [String] 'individual' or 'group' (default: 'individual')
      def send_text(phone_number_id:, to:, body:, preview_url: nil, recipient_type: 'individual',
                    context_message_id: nil, biz_opaque_callback_data: nil)
        payload = build_base_payload(
          phone_number_id: phone_number_id,
          to: to,
          type: 'text',
          recipient_type: recipient_type,
          context_message_id: context_message_id,
          biz_opaque_callback_data: biz_opaque_callback_data
        )
        
        payload[:text] = { body: body }
        payload[:text][:preview_url] = preview_url unless preview_url.nil?
        
        response = @client.request(:post, "#{phone_number_id}/messages", 
                                   body: payload.to_json, response_type: :json)
        Types::SendMessageResponse.new(response)
      end

      # Image Messages
      # @param recipient_type [String] 'individual' or 'group' (default: 'individual')
      def send_image(phone_number_id:, to:, image:, caption: nil, recipient_type: 'individual',
                     context_message_id: nil, biz_opaque_callback_data: nil)
        payload = build_base_payload(
          phone_number_id: phone_number_id,
          to: to,
          type: 'image',
          recipient_type: recipient_type,
          context_message_id: context_message_id,
          biz_opaque_callback_data: biz_opaque_callback_data
        )
        
        image_obj = build_media_object(image, caption)
        payload[:image] = image_obj
        
        response = @client.request(:post, "#{phone_number_id}/messages", 
                                   body: payload.to_json, response_type: :json)
        Types::SendMessageResponse.new(response)
      end

      # Audio Messages  
      # @param phone_number_id [String] Phone number ID
      # @param to [String] Recipient WhatsApp ID
      # @param audio [Hash, String] Audio media (id or link)
      # @param voice [Boolean] Set true for voice notes (OGG/OPUS format)
      def send_audio(phone_number_id:, to:, audio:, voice: false,
                     context_message_id: nil, biz_opaque_callback_data: nil)
        payload = build_base_payload(
          phone_number_id: phone_number_id,
          to: to,
          type: 'audio',
          context_message_id: context_message_id,
          biz_opaque_callback_data: biz_opaque_callback_data
        )
        
        audio_obj = build_media_object(audio)
        
        # Add voice flag for voice notes (OGG/OPUS format recommended)
        if voice
          audio_obj[:voice] = true
        end
        
        payload[:audio] = audio_obj
        
        response = @client.request(:post, "#{phone_number_id}/messages", 
                                   body: payload.to_json, response_type: :json)
        Types::SendMessageResponse.new(response)
      end

      # Document Messages
      def send_document(phone_number_id:, to:, document:, caption: nil, filename: nil, 
                        context_message_id: nil, biz_opaque_callback_data: nil)
        payload = build_base_payload(
          phone_number_id: phone_number_id,
          to: to,
          type: 'document',
          context_message_id: context_message_id,
          biz_opaque_callback_data: biz_opaque_callback_data
        )
        
        document_obj = build_media_object(document, caption)
        document_obj[:filename] = filename if filename
        payload[:document] = document_obj
        
        response = @client.request(:post, "#{phone_number_id}/messages", 
                                   body: payload.to_json, response_type: :json)
        Types::SendMessageResponse.new(response)
      end

      # Video Messages
      # @param recipient_type [String] 'individual' or 'group' (default: 'individual')
      def send_video(phone_number_id:, to:, video:, caption: nil, recipient_type: 'individual',
                     context_message_id: nil, biz_opaque_callback_data: nil)
        payload = build_base_payload(
          phone_number_id: phone_number_id,
          to: to,
          type: 'video',
          recipient_type: recipient_type,
          context_message_id: context_message_id,
          biz_opaque_callback_data: biz_opaque_callback_data
        )
        
        payload[:video] = build_media_object(video, caption)
        
        response = @client.request(:post, "#{phone_number_id}/messages", 
                                   body: payload.to_json, response_type: :json)
        Types::SendMessageResponse.new(response)
      end

      # Sticker Messages
      def send_sticker(phone_number_id:, to:, sticker:, context_message_id: nil,
                       biz_opaque_callback_data: nil)
        payload = build_base_payload(
          phone_number_id: phone_number_id,
          to: to,
          type: 'sticker',
          context_message_id: context_message_id,
          biz_opaque_callback_data: biz_opaque_callback_data
        )
        
        payload[:sticker] = build_media_object(sticker)
        
        response = @client.request(:post, "#{phone_number_id}/messages", 
                                   body: payload.to_json, response_type: :json)
        Types::SendMessageResponse.new(response)
      end

      # Location Messages
      def send_location(phone_number_id:, to:, latitude:, longitude:, name: nil, 
                        address: nil, context_message_id: nil, biz_opaque_callback_data: nil)
        payload = build_base_payload(
          phone_number_id: phone_number_id,
          to: to,
          type: 'location',
          context_message_id: context_message_id,
          biz_opaque_callback_data: biz_opaque_callback_data
        )
        
        location_obj = {
          latitude: latitude,
          longitude: longitude
        }
        location_obj[:name] = name if name
        location_obj[:address] = address if address
        
        payload[:location] = location_obj
        
        response = @client.request(:post, "#{phone_number_id}/messages", 
                                   body: payload.to_json, response_type: :json)
        Types::SendMessageResponse.new(response)
      end

      # Contact Messages
      def send_contacts(phone_number_id:, to:, contacts:, context_message_id: nil,
                        biz_opaque_callback_data: nil)
        payload = build_base_payload(
          phone_number_id: phone_number_id,
          to: to,
          type: 'contacts',
          context_message_id: context_message_id,
          biz_opaque_callback_data: biz_opaque_callback_data
        )
        
        payload[:contacts] = contacts
        
        response = @client.request(:post, "#{phone_number_id}/messages", 
                                   body: payload.to_json, response_type: :json)
        Types::SendMessageResponse.new(response)
      end

      # Template Messages
      def send_template(phone_number_id:, to:, name:, language:, components: nil,
                        context_message_id: nil, biz_opaque_callback_data: nil)
        payload = build_base_payload(
          phone_number_id: phone_number_id,
          to: to,
          type: 'template',
          context_message_id: context_message_id,
          biz_opaque_callback_data: biz_opaque_callback_data
        )
        
        template_obj = {
          name: name,
          language: { code: language }
        }
        template_obj[:components] = components if components
        
        payload[:template] = template_obj
        
        response = @client.request(:post, "#{phone_number_id}/messages", 
                                   body: payload.to_json, response_type: :json)
        Types::SendMessageResponse.new(response)
      end

      # Reaction Messages
      def send_reaction(phone_number_id:, to:, message_id:, emoji: nil, 
                        context_message_id: nil, biz_opaque_callback_data: nil)
        payload = build_base_payload(
          phone_number_id: phone_number_id,
          to: to,
          type: 'reaction',
          context_message_id: context_message_id,
          biz_opaque_callback_data: biz_opaque_callback_data
        )
        
        reaction_obj = { message_id: message_id }
        reaction_obj[:emoji] = emoji if emoji  # nil emoji removes reaction
        
        payload[:reaction] = reaction_obj
        
        response = @client.request(:post, "#{phone_number_id}/messages", 
                                   body: payload.to_json, response_type: :json)
        Types::SendMessageResponse.new(response)
      end

      # Interactive Button Messages
      # @param phone_number_id [String] Phone number ID
      # @param to [String] Recipient WhatsApp ID
      # @param body_text [String] Message body text
      # @param buttons [Array<Hash>] Array of button objects (max 3)
      # @param header [Hash, nil] Optional header (text, image, video, or document)
      # @param footer [Hash, String, nil] Optional footer text or object
      def send_interactive_buttons(phone_number_id:, to:, body_text:, buttons:, 
                                   header: nil, footer: nil, context_message_id: nil,
                                   biz_opaque_callback_data: nil)
        # Validate button count (max 3 buttons)
        if buttons.length > 3
          raise ArgumentError, "Maximum 3 buttons allowed (current: #{buttons.length})"
        end
        
        if buttons.empty?
          raise ArgumentError, 'At least 1 button is required'
        end
        
        # Validate header if provided (now supports text, image, video, document)
        if header
          validate_interactive_header(header, 'button')
        end
        
        payload = build_base_payload(
          phone_number_id: phone_number_id,
          to: to,
          type: 'interactive',
          context_message_id: context_message_id,
          biz_opaque_callback_data: biz_opaque_callback_data
        )
        
        interactive_obj = {
          type: 'button',
          body: { text: body_text },
          action: { buttons: buttons }
        }
        
        # Add header (supports text and media types)
        interactive_obj[:header] = header if header
        
        # Add footer (handle both string and hash formats)
        if footer
          interactive_obj[:footer] = footer.is_a?(String) ? { text: footer } : footer
        end
        
        payload[:interactive] = interactive_obj
        
        response = @client.request(:post, "#{phone_number_id}/messages", 
                                   body: payload.to_json, response_type: :json)
        Types::SendMessageResponse.new(response)
      end

      # Interactive List Messages
      # @param phone_number_id [String] Phone number ID
      # @param to [String] Recipient WhatsApp ID
      # @param body_text [String] Message body text (max 4096 characters)
      # @param button_text [String] Button text (list trigger)
      # @param sections [Array<Hash>] List sections (max 10 rows total)
      # @param header [Hash, nil] Optional text header only
      # @param footer [Hash, String, nil] Optional footer text or object
      def send_interactive_list(phone_number_id:, to:, body_text:, button_text:, sections:,
                                header: nil, footer: nil, context_message_id: nil,
                                biz_opaque_callback_data: nil)
        # Validate body text length (updated to 4096)
        if body_text.length > 4096
          raise ArgumentError, "Body text max 4096 characters (current: #{body_text.length})"
        end
        
        # Validate total row count (max 10 across all sections)
        total_rows = sections.sum do |section|
          rows = section[:rows] || section['rows'] || []
          rows.length
        end
        
        if total_rows > 10
          raise ArgumentError, "Maximum 10 rows total across all sections (current: #{total_rows})"
        end
        
        if total_rows == 0
          raise ArgumentError, 'At least 1 row is required'
        end
        
        # Header for lists must be text type only  
        if header
          header_type = header[:type] || header['type']
          unless header_type.nil? || header_type.to_s == 'text'
            raise ArgumentError, "List messages only support text headers (received: #{header_type})"
          end
          validate_text_header(header) if header_type
        end
        
        payload = build_base_payload(
          phone_number_id: phone_number_id,
          to: to,
          type: 'interactive',
          context_message_id: context_message_id,
          biz_opaque_callback_data: biz_opaque_callback_data
        )
        
        interactive_obj = {
          type: 'list',
          body: { text: body_text },
          action: {
            button: button_text,
            sections: sections
          }
        }
        
        interactive_obj[:header] = header if header
        
        # Add footer (handle both string and hash formats)
        if footer
          interactive_obj[:footer] = footer.is_a?(String) ? { text: footer } : footer
        end
        
        payload[:interactive] = interactive_obj
        
        response = @client.request(:post, "#{phone_number_id}/messages", 
                                   body: payload.to_json, response_type: :json)
        Types::SendMessageResponse.new(response)
      end

      # Send Flow Message
      def send_flow(phone_number_id:, to:, flow_id:, flow_cta:, flow_token:,
                    screen: nil, flow_action: 'navigate', mode: 'published',
                    flow_action_payload: nil, header: nil, body_text: nil,
                    footer_text: nil, context_message_id: nil,
                    biz_opaque_callback_data: nil)
        payload = build_base_payload(
          phone_number_id: phone_number_id,
          to: to,
          type: 'interactive',
          context_message_id: context_message_id,
          biz_opaque_callback_data: biz_opaque_callback_data
        )
        
        # Build Flow action parameters
        action_params = {
          flow_message_version: '3',
          flow_token: flow_token,
          flow_id: flow_id,
          flow_cta: flow_cta,
          flow_action: flow_action,
          mode: mode
        }
        
        # Add optional parameters
        action_params[:flow_action_payload] = flow_action_payload if flow_action_payload
        
        # Add screen parameter for navigate action
        if flow_action == 'navigate' && screen
          action_params[:flow_action_payload] ||= {}
          action_params[:flow_action_payload][:screen] = screen
        end
        
        interactive_obj = {
          type: 'flow',
          action: action_params
        }
        
        # Add optional header and body
        interactive_obj[:header] = header if header
        interactive_obj[:body] = { text: body_text } if body_text
        interactive_obj[:footer] = { text: footer_text } if footer_text
        
        payload[:interactive] = interactive_obj
        
        response = @client.request(:post, "#{phone_number_id}/messages",
                                   body: payload.to_json, response_type: :json)
        Types::SendMessageResponse.new(response)
      end

      # Send Interactive CTA URL Message
      # @param phone_number_id [String] Phone number ID
      # @param to [String] Recipient WhatsApp ID
      # @param body_text [String] Message body text (max 1024 characters)
      # @param display_text [String] Button display text (max 20 characters)
      # @param url [String] Target URL (must be HTTPS)
      # @param header [Hash, nil] Optional header (text, image, video, or document)
      # @param footer_text [String, nil] Optional footer text (max 60 characters)
      def send_interactive_cta_url(phone_number_id:, to:, body_text:, display_text:, url:,
                                    header: nil, footer_text: nil, context_message_id: nil,
                                    biz_opaque_callback_data: nil)
        # Validate parameters
        validate_cta_url_params(body_text, display_text, url, footer_text)
        
        payload = build_base_payload(
          phone_number_id: phone_number_id,
          to: to,
          type: 'interactive',
          context_message_id: context_message_id,
          biz_opaque_callback_data: biz_opaque_callback_data
        )
        
        interactive_obj = {
          type: 'cta_url',
          body: { text: body_text },
          action: {
            name: 'cta_url',
            parameters: {
              display_text: display_text,
              url: url
            }
          }
        }
        
        # Add optional header (supports text, image, video, document)
        if header
          validate_interactive_header(header, 'cta_url')
          interactive_obj[:header] = header
        end
        
        # Add optional footer
        interactive_obj[:footer] = { text: footer_text } if footer_text
        
        payload[:interactive] = interactive_obj
        
        response = @client.request(:post, "#{phone_number_id}/messages",
                                   body: payload.to_json, response_type: :json)
        Types::SendMessageResponse.new(response)
      end

      # Send Interactive Catalog Message
      # @param phone_number_id [String] Phone number ID
      # @param to [String] Recipient WhatsApp ID
      # @param body_text [String] Message body text (max 1024 characters)
      # @param thumbnail_product_retailer_id [String] Product retailer ID for thumbnail
      # @param footer_text [String, nil] Optional footer text (max 60 characters)
      def send_interactive_catalog_message(phone_number_id:, to:, body_text:,
                                          thumbnail_product_retailer_id:,
                                          footer_text: nil, context_message_id: nil,
                                          biz_opaque_callback_data: nil)
        # Validate parameters
        validate_catalog_message_params(body_text, thumbnail_product_retailer_id, footer_text)
        
        payload = build_base_payload(
          phone_number_id: phone_number_id,
          to: to,
          type: 'interactive',
          context_message_id: context_message_id,
          biz_opaque_callback_data: biz_opaque_callback_data
        )
        
        interactive_obj = {
          type: 'catalog_message',
          body: { text: body_text },
          action: {
            name: 'catalog_message',
            parameters: {
              thumbnail_product_retailer_id: thumbnail_product_retailer_id
            }
          }
        }
        
        # Add optional footer
        interactive_obj[:footer] = { text: footer_text } if footer_text
        
        payload[:interactive] = interactive_obj
        
        response = @client.request(:post, "#{phone_number_id}/messages",
                                   body: payload.to_json, response_type: :json)
        Types::SendMessageResponse.new(response)
      end

      # Send Interactive Location Request
      # @param phone_number_id [String] Phone number ID
      # @param to [String] Recipient WhatsApp ID
      # @param body_text [String] Message body text
      # @param header [Hash, nil] Optional header (text, image, video, or document)
      # @param footer_text [String, nil] Optional footer text
      def send_interactive_location_request(phone_number_id:, to:, body_text:,
                                           header: nil, footer_text: nil,
                                           context_message_id: nil,
                                           biz_opaque_callback_data: nil)
        payload = build_base_payload(
          phone_number_id: phone_number_id,
          to: to,
          type: 'interactive',
          context_message_id: context_message_id,
          biz_opaque_callback_data: biz_opaque_callback_data
        )
        
        interactive_obj = {
          type: 'location_request_message',
          body: { text: body_text },
          action: {
            name: 'send_location'
          }
        }
        
        # Add optional header (supports text, image, video, document)
        if header
          validate_interactive_header(header, 'location_request')
          interactive_obj[:header] = header
        end
        
        # Add optional footer
        interactive_obj[:footer] = { text: footer_text } if footer_text
        
        payload[:interactive] = interactive_obj
        
        response = @client.request(:post, "#{phone_number_id}/messages",
                                   body: payload.to_json, response_type: :json)
        Types::SendMessageResponse.new(response)
      end

      # Mark Message as Read
      def mark_read(phone_number_id:, message_id:)
        payload = {
          messaging_product: 'whatsapp',
          status: 'read',
          message_id: message_id
        }
        
        response = @client.request(:post, "#{phone_number_id}/messages", 
                                   body: payload.to_json, response_type: :json)
        Types::GraphSuccessResponse.new(response)
      end

      # Send Typing Indicator
      def send_typing_indicator(phone_number_id:, to:)
        payload = {
          messaging_product: 'whatsapp',
          recipient_type: 'individual',
          to: to,
          type: 'text',
          text: { typing_indicator: { type: 'text' } }
        }
        
        response = @client.request(:post, "#{phone_number_id}/messages", 
                                   body: payload.to_json, response_type: :json)
        Types::GraphSuccessResponse.new(response)
      end

      # Query Message History (Kapso Proxy only)
      def query(phone_number_id:, direction: nil, status: nil, since: nil, until_time: nil,
                conversation_id: nil, limit: nil, after: nil, before: nil, fields: nil)
        assert_kapso_proxy('Message history API')
        
        query_params = {
          phone_number_id: phone_number_id,
          direction: direction,
          status: status,
          since: since,
          until: until_time,
          conversation_id: conversation_id,
          limit: limit,
          after: after,
          before: before,
          fields: fields
        }.compact
        
        response = @client.request(:get, "#{phone_number_id}/messages", 
                                   query: query_params, response_type: :json)
        Types::PagedResponse.new(response)
      end

      # List Messages by Conversation (Kapso Proxy only)
      def list_by_conversation(phone_number_id:, conversation_id:, limit: nil, 
                               after: nil, before: nil, fields: nil)
        query(
          phone_number_id: phone_number_id,
          conversation_id: conversation_id,
          limit: limit,
          after: after,
          before: before,
          fields: fields
        )
      end

      private

      def build_base_payload(phone_number_id:, to:, type:, recipient_type: 'individual',
                             context_message_id: nil, biz_opaque_callback_data: nil)
        # Validate recipient_type
        valid_types = ['individual', 'group']
        unless valid_types.include?(recipient_type)
          raise ArgumentError, "recipient_type must be 'individual' or 'group' (received: #{recipient_type})"
        end
        
        payload = {
          messaging_product: 'whatsapp',
          recipient_type: recipient_type,
          to: to,
          type: type
        }
        
        if context_message_id
          payload[:context] = { message_id: context_message_id }
        end
        
        if biz_opaque_callback_data
          payload[:biz_opaque_callback_data] = biz_opaque_callback_data
        end
        
        payload
      end

      def build_media_object(media, caption = nil)
        media_obj = case media
                    when Hash
                      media.dup
                    when String
                      # Assume it's either a media ID or URL
                      if media.match?(/\A\w+\z/) # Simple alphanumeric ID
                        { id: media }
                      else
                        { link: media }
                      end
                    else
                      raise ArgumentError, 'Media must be a Hash, media ID string, or URL string'
                    end
        
        media_obj[:caption] = caption if caption
        media_obj
      end

      def assert_kapso_proxy(feature)
        unless @client.kapso_proxy?
          raise Errors::KapsoProxyRequiredError.new(feature)
        end
      end

      # Validate CTA URL parameters
      def validate_cta_url_params(body_text, display_text, url, footer_text)
        # Body text validation
        if body_text.nil? || body_text.strip.empty?
          raise ArgumentError, 'body_text is required'
        end
        
        if body_text.length > 1024
          raise ArgumentError, "body_text max 1024 characters (current: #{body_text.length})"
        end
        
        # Display text validation
        if display_text.nil? || display_text.strip.empty?
          raise ArgumentError, 'display_text is required'
        end
        
        if display_text.length > 20
          raise ArgumentError, "display_text max 20 characters (current: #{display_text.length})"
        end
        
        # URL validation
        if url.nil? || url.strip.empty?
          raise ArgumentError, 'url is required'
        end
        
        unless url.match?(%r{\Ahttps?://}i)
          raise ArgumentError, 'url must start with http:// or https://'
        end
        
        # Footer text validation
        if footer_text && footer_text.length > 60
          raise ArgumentError, "footer_text max 60 characters (current: #{footer_text.length})"
        end
      end

      # Validate catalog message parameters
      def validate_catalog_message_params(body_text, thumbnail_product_retailer_id, footer_text)
        # Body text validation
        if body_text.nil? || body_text.strip.empty?
          raise ArgumentError, 'body_text is required'
        end
        
        if body_text.length > 1024
          raise ArgumentError, "body_text max 1024 characters (current: #{body_text.length})"
        end
        
        # Thumbnail product ID validation
        if thumbnail_product_retailer_id.nil? || thumbnail_product_retailer_id.to_s.strip.empty?
          raise ArgumentError, 'thumbnail_product_retailer_id is required'
        end
        
        # Footer text validation
        if footer_text && footer_text.length > 60
          raise ArgumentError, "footer_text max 60 characters (current: #{footer_text.length})"
        end
      end

      # Validate interactive message header
      def validate_interactive_header(header, message_type = 'interactive')
        valid_types = ['text', 'image', 'video', 'document']
        header_type = header[:type] || header['type']
        
        if header_type.nil?
          raise ArgumentError, 'Header must have a type field'
        end
        
        unless valid_types.include?(header_type.to_s)
          raise ArgumentError, "Invalid header type '#{header_type}'. Must be one of: #{valid_types.join(', ')}"
        end
        
        case header_type.to_s
        when 'text'
          validate_text_header(header)
        when 'image', 'video', 'document'
          validate_media_header(header)
        end
      end

      # Validate text header
      def validate_text_header(header)
        text = header[:text] || header['text']
        
        if text.nil? || text.strip.empty?
          raise ArgumentError, 'Text header requires text field'
        end
        
        if text.length > 60
          raise ArgumentError, "Header text max 60 characters (current: #{text.length})"
        end
      end

      # Validate media header (image, video, document)
      def validate_media_header(header)
        header_type = (header[:type] || header['type']).to_s
        media = header[header_type.to_sym] || header[header_type]
        
        if media.nil?
          raise ArgumentError, "#{header_type.capitalize} header requires #{header_type} field"
        end
        
        # Media must have id or link
        has_id = media[:id] || media['id']
        has_link = media[:link] || media['link']
        
        unless has_id || has_link
          raise ArgumentError, "#{header_type.capitalize} must have 'id' or 'link'"
        end
      end
    end
  end
end