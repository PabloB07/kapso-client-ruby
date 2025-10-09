# frozen_string_literal: true

module KapsoClientRuby
  module Rails
    # Service class for Rails integration with KapsoClientRuby
    # Provides a convenient interface for Rails applications to interact with the Kapso API
    class Service
      include ActiveSupport::Configurable

      # @return [KapsoClientRuby::Client] The configured Kapso client
      attr_reader :client

      def initialize(client = nil)
        @client = client || KapsoClientRuby::Client.new
      end

      # Send a text message
      # @param to [String] The recipient's phone number
      # @param text [String] The message text
      # @param options [Hash] Additional options
      # @return [Hash] API response
      def send_text_message(to:, text:, **options)
        Rails.logger.info "Sending text message to #{to}: #{text.truncate(50)}"
        
        result = client.messages.send_text(
          to: to,
          text: text,
          **options
        )
        
        Rails.logger.info "Message sent successfully. ID: #{result.dig('messages', 0, 'id')}"
        result
      rescue KapsoClientRuby::Error => e
        Rails.logger.error "Failed to send text message: #{e.message}"
        raise
      end

      # Send a template message
      # @param to [String] The recipient's phone number
      # @param template_name [String] The template name
      # @param language [String] The language code (default: 'en')
      # @param components [Array] Template components
      # @return [Hash] API response
      def send_template_message(to:, template_name:, language: 'en', components: [])
        Rails.logger.info "Sending template message '#{template_name}' to #{to}"
        
        result = client.messages.send_template(
          to: to,
          name: template_name,
          language: language,
          components: components
        )
        
        Rails.logger.info "Template message sent successfully. ID: #{result.dig('messages', 0, 'id')}"
        result
      rescue KapsoClientRuby::Error => e
        Rails.logger.error "Failed to send template message: #{e.message}"
        raise
      end

      # Send a media message
      # @param to [String] The recipient's phone number
      # @param media_type [String] Type of media ('image', 'document', 'video', 'audio')
      # @param media_url [String] URL of the media file
      # @param options [Hash] Additional options
      # @return [Hash] API response
      def send_media_message(to:, media_type:, media_url:, **options)
        Rails.logger.info "Sending #{media_type} message to #{to}: #{media_url}"
        
        result = client.messages.send_media(
          to: to,
          type: media_type,
          media_url: media_url,
          **options
        )
        
        Rails.logger.info "Media message sent successfully. ID: #{result.dig('messages', 0, 'id')}"
        result
      rescue KapsoClientRuby::Error => e
        Rails.logger.error "Failed to send media message: #{e.message}"
        raise
      end

      # Upload media file
      # @param file_path [String] Path to the media file
      # @param media_type [String] Type of media
      # @return [Hash] Upload response with media ID
      def upload_media(file_path:, media_type:)
        Rails.logger.info "Uploading media file: #{file_path}"
        
        result = client.media.upload(
          file_path: file_path,
          type: media_type
        )
        
        Rails.logger.info "Media uploaded successfully. ID: #{result['id']}"
        result
      rescue KapsoClientRuby::Error => e
        Rails.logger.error "Failed to upload media: #{e.message}"
        raise
      end

      # Get message status
      # @param message_id [String] The message ID
      # @return [Hash] Message status
      def get_message_status(message_id)
        Rails.logger.debug "Getting status for message: #{message_id}"
        
        result = client.messages.get_status(message_id)
        
        Rails.logger.debug "Message status: #{result['status']}"
        result
      rescue KapsoClientRuby::Error => e
        Rails.logger.error "Failed to get message status: #{e.message}"
        raise
      end

      # Get templates
      # @param options [Hash] Query options
      # @return [Array] List of templates
      def get_templates(**options)
        Rails.logger.debug "Fetching templates with options: #{options}"
        
        result = client.templates.list(**options)
        
        Rails.logger.debug "Found #{result['data']&.length || 0} templates"
        result
      rescue KapsoClientRuby::Error => e
        Rails.logger.error "Failed to fetch templates: #{e.message}"
        raise
      end

      # Process incoming webhook
      # @param webhook_data [Hash] The webhook payload
      # @return [Hash] Processed webhook data
      def process_webhook(webhook_data)
        Rails.logger.info "Processing webhook: #{webhook_data}"
        
        # Process webhook data based on type
        entries = webhook_data['entry'] || []
        
        entries.each do |entry|
          changes = entry['changes'] || []
          
          changes.each do |change|
            case change['field']
            when 'messages'
              process_message_webhook(change['value'])
            when 'message_template_status_update'
              process_template_status_webhook(change['value'])
            else
              Rails.logger.warn "Unknown webhook field: #{change['field']}"
            end
          end
        end
        
        { status: 'processed' }
      rescue => e
        Rails.logger.error "Failed to process webhook: #{e.message}"
        raise
      end

      private

      def process_message_webhook(value)
        messages = value['messages'] || []
        statuses = value['statuses'] || []
        
        messages.each do |message|
          Rails.logger.info "Received message: #{message['id']} from #{message['from']}"
          # Trigger Rails callback or event
          ActiveSupport::Notifications.instrument('kapso.message_received', message: message)
        end
        
        statuses.each do |status|
          Rails.logger.info "Message status update: #{status['id']} -> #{status['status']}"
          # Trigger Rails callback or event
          ActiveSupport::Notifications.instrument('kapso.message_status_updated', status: status)
        end
      end

      def process_template_status_webhook(value)
        Rails.logger.info "Template status update: #{value}"
        # Trigger Rails callback or event
        ActiveSupport::Notifications.instrument('kapso.template_status_updated', template_status: value)
      end
    end
  end
end