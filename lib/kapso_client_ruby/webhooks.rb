# frozen_string_literal: true

require 'openssl'
require 'json'

module KapsoClientRuby
  module Webhooks
    class << self
      # Verify X-Hub-Signature-256 for WhatsApp Webhooks using your app secret.
      # Returns true when the signature matches the request body.
      #
      # @param app_secret [String] Your Meta app secret
      # @param raw_body [String] The raw request body as a string
      # @param signature_header [String, nil] The X-Hub-Signature-256 header value
      # @return [Boolean] true if signature is valid
      #
      # @example
      #   valid = KapsoClientRuby::Webhooks.verify_signature(
      #     app_secret: ENV['META_APP_SECRET'],
      #     raw_body: request.body.read,
      #     signature_header: request.headers['X-Hub-Signature-256']
      #   )
      def verify_signature(app_secret:, raw_body:, signature_header:)
        return false if signature_header.nil? || signature_header.to_s.empty?

        parts = signature_header.to_s.split('=')
        return false if parts.length != 2

        algo, received = parts
        return false if algo != 'sha256' || received.nil? || received.empty?

        body = raw_body.is_a?(String) ? raw_body : raw_body.to_s
        expected = OpenSSL::HMAC.hexdigest('sha256', app_secret, body)

        # Constant-time comparison to prevent timing attacks
        secure_compare(received, expected)
      end

      # Normalize a webhook payload into a structured format.
      # Returns messages, statuses, calls, and contacts with camelCase keys converted to snake_case.
      #
      # @param payload [Hash] The raw webhook payload from Meta
      # @return [Hash] Normalized webhook data with :messages, :statuses, :calls, :contacts, :raw
      #
      # @example
      #   result = KapsoClientRuby::Webhooks.normalize_webhook(payload)
      #   result[:messages].each do |message|
      #     puts message['id']
      #   end
      def normalize_webhook(payload)
        result = {
          object: nil,
          phone_number_id: nil,
          display_phone_number: nil,
          contacts: [],
          messages: [],
          statuses: [],
          calls: [],
          raw: {}
        }

        return result unless payload.is_a?(Hash)

        result[:object] = payload['object'] if payload['object'].is_a?(String)

        entries = payload['entry'].is_a?(Array) ? payload['entry'] : []

        entries.each do |entry|
          changes = entry.is_a?(Hash) && entry['changes'].is_a?(Array) ? entry['changes'] : []

          changes.each do |change|
            raw_value = change.is_a?(Hash) ? change['value'] : nil
            next unless raw_value.is_a?(Hash)

            value = Types.deep_snake_case_keys(raw_value)
            field_key = to_snake_case_field(change['field'])

            if field_key
              result[:raw][field_key] ||= []
              result[:raw][field_key] << value
            end

            metadata = value.is_a?(Hash) ? (value[:metadata] || {}) : {}

            result[:phone_number_id] = metadata[:phone_number_id] if metadata[:phone_number_id].is_a?(String)
            result[:display_phone_number] = metadata[:display_phone_number] if metadata[:display_phone_number].is_a?(String)

            contacts = value.is_a?(Hash) && value[:contacts].is_a?(Array) ? value[:contacts] : []
            contacts.each do |contact|
              result[:contacts] << Types.deep_snake_case_keys(contact)
            end

            messages = value.is_a?(Hash) && value[:messages].is_a?(Array) ? value[:messages] : []
            message_echoes = value.is_a?(Hash) && value[:message_echoes].is_a?(Array) ? value[:message_echoes] : []

            (messages + message_echoes).each do |message|
              normalized = normalize_message(message)
              apply_direction(normalized, metadata, message_echoes.include?(message))
              result[:messages] << normalized
            end

            statuses = value.is_a?(Hash) && value[:statuses].is_a?(Array) ? value[:statuses] : []
            statuses.each do |status|
              result[:statuses] << Types.deep_snake_case_keys(status)
            end

            calls = value.is_a?(Hash) && value[:calls].is_a?(Array) ? value[:calls] : []
            calls.each do |call|
              normalized_call = Types.deep_snake_case_keys(call)
              if normalized_call[:wacid].is_a?(String) && !normalized_call[:call_id]
                normalized_call[:call_id] = normalized_call.delete(:wacid)
              end
              result[:calls] << normalized_call
            end
          end
        end

        result
      end

      private

      # Constant-time string comparison to prevent timing attacks
      def secure_compare(a, b)
        return false unless a.bytesize == b.bytesize

        a_bytes = a.bytes
        b_bytes = b.bytes
        result = 0

        a_bytes.each_with_index do |byte, i|
          result |= byte ^ b_bytes[i]
        end

        result.zero?
      end

      # Normalize a single message, handling Flow responses and order text
      def normalize_message(message)
        return {} unless message.is_a?(Hash)

        normalized = Types.deep_snake_case_keys(message)

        # Handle order text
        if normalized[:order].is_a?(Hash) && normalized[:order][:text]
          order_text = normalized[:order].delete(:text)
          normalized[:order][:order_text] = order_text
          ensure_kapso(normalized)[:order_text] = order_text
        end

        # Handle Flow response in interactive messages
        if normalized.dig(:interactive, :type) == 'nfm_reply' &&
           normalized.dig(:interactive, :nfm_reply, :response_json).is_a?(String)

          nfm = normalized[:interactive][:nfm_reply]
          response_json = nfm[:response_json]

          begin
            parsed = JSON.parse(response_json)
            camel = Types.deep_camel_case_keys(parsed)
            kapso = ensure_kapso(normalized)
            kapso[:flow_response] = camel
            kapso[:flow_token] = camel['flowToken'] if camel['flowToken']
            kapso[:flow_name] = nfm[:name] if nfm[:name]
          rescue JSON::ParserError
            # Ignore parse failure, keep original string
          end
        end

        # Remove empty kapso hash
        normalized.delete(:kapso) if normalized[:kapso].is_a?(Hash) && normalized[:kapso].empty?

        normalized
      end

      # Apply direction (inbound/outbound) to a message
      def apply_direction(message, metadata, is_echo)
        business_candidates = []
        phone_number_id = metadata[:phone_number_id]
        display_phone_number = metadata[:display_phone_number]
        context_from = message.dig(:context, :from)

        business_candidates << phone_number_id if phone_number_id
        business_candidates << display_phone_number if display_phone_number
        business_candidates << context_from if context_from

        business_set = business_candidates.map { |num| normalize_number(num) }.to_set

        from_norm = normalize_number(message[:from])
        to_norm = normalize_number(message[:to])

        if is_echo
          direction = 'outbound'
        elsif from_norm && business_set.include?(from_norm)
          direction = 'outbound'
        elsif to_norm && business_set.include?(to_norm)
          direction = 'inbound'
        elsif context_from && business_set.include?(normalize_number(context_from))
          direction = 'inbound'
        elsif from_norm
          direction = 'inbound'
        end

        if direction || is_echo
          kapso = ensure_kapso(message)
          kapso[:direction] = direction if direction
          kapso[:source] = 'smb_message_echo' if is_echo
        end
      end

      # Normalize a phone number by removing non-digits
      def normalize_number(value)
        return '' unless value.is_a?(String)
        value.gsub(/[^0-9]/, '')
      end

      # Ensure the message has a kapso extensions hash
      def ensure_kapso(message)
        message[:kapso] ||= {}
      end

      # Convert a field name to snake_case
      def to_snake_case_field(field)
        return nil unless field.is_a?(String) && !field.empty?
        field.gsub(/([A-Z])/) { |m| "_#{m.downcase}" }.sub(/^_/, '')
      end
    end
  end
end
