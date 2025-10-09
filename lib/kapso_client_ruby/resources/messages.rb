# frozen_string_literal: true

module KapsoClientRuby
  module Resources
    class Messages
      def initialize(client)
        @client = client
      end

      # Text Messages
      def send_text(phone_number_id:, to:, body:, preview_url: nil, context_message_id: nil, 
                    biz_opaque_callback_data: nil)
        payload = build_base_payload(
          phone_number_id: phone_number_id,
          to: to,
          type: 'text',
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
      def send_image(phone_number_id:, to:, image:, caption: nil, context_message_id: nil,
                     biz_opaque_callback_data: nil)
        payload = build_base_payload(
          phone_number_id: phone_number_id,
          to: to,
          type: 'image',
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
      def send_audio(phone_number_id:, to:, audio:, context_message_id: nil,
                     biz_opaque_callback_data: nil)
        payload = build_base_payload(
          phone_number_id: phone_number_id,
          to: to,
          type: 'audio',
          context_message_id: context_message_id,
          biz_opaque_callback_data: biz_opaque_callback_data
        )
        
        payload[:audio] = build_media_object(audio)
        
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
      def send_video(phone_number_id:, to:, video:, caption: nil, context_message_id: nil,
                     biz_opaque_callback_data: nil)
        payload = build_base_payload(
          phone_number_id: phone_number_id,
          to: to,
          type: 'video',
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
      def send_interactive_buttons(phone_number_id:, to:, body_text:, buttons:, 
                                   header: nil, footer: nil, context_message_id: nil,
                                   biz_opaque_callback_data: nil)
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
        
        interactive_obj[:header] = header if header
        interactive_obj[:footer] = footer if footer
        
        payload[:interactive] = interactive_obj
        
        response = @client.request(:post, "#{phone_number_id}/messages", 
                                   body: payload.to_json, response_type: :json)
        Types::SendMessageResponse.new(response)
      end

      # Interactive List Messages
      def send_interactive_list(phone_number_id:, to:, body_text:, button_text:, sections:,
                                header: nil, footer: nil, context_message_id: nil,
                                biz_opaque_callback_data: nil)
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
        interactive_obj[:footer] = footer if footer
        
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

      def build_base_payload(phone_number_id:, to:, type:, context_message_id: nil, 
                             biz_opaque_callback_data: nil)
        payload = {
          messaging_product: 'whatsapp',
          recipient_type: 'individual',
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
    end
  end
end