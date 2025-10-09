# frozen_string_literal: true

module KapsoClientRuby
  module Resources
    class Templates
      def initialize(client)
        @client = client
      end

      # List templates for a business account
      def list(business_account_id:, limit: nil, after: nil, before: nil, 
               name: nil, status: nil, category: nil, language: nil, 
               name_or_content: nil, quality_score: nil)
        query_params = {
          limit: limit,
          after: after,
          before: before,
          name: name,
          status: status,
          category: category,
          language: language,
          name_or_content: name_or_content,
          quality_score: quality_score
        }.compact
        
        response = @client.request(:get, "#{business_account_id}/message_templates", 
                                   query: query_params, response_type: :json)
        Types::PagedResponse.new(response, Types::MessageTemplate)
      end

      # Get a specific template
      def get(business_account_id:, template_id:, fields: nil)
        query_params = {}
        query_params[:fields] = fields if fields
        
        response = @client.request(:get, "#{business_account_id}/message_templates/#{template_id}", 
                                   query: query_params, response_type: :json)
        Types::MessageTemplate.new(response)
      end

      # Create a new template
      def create(business_account_id:, name:, language:, category:, components:, 
                 allow_category_change: nil, message_send_ttl_seconds: nil)
        validate_template_data(name: name, language: language, category: category, components: components)
        
        payload = {
          name: name,
          language: language,
          category: category,
          components: normalize_components(components)
        }
        
        payload[:allow_category_change] = allow_category_change unless allow_category_change.nil?
        payload[:message_send_ttl_seconds] = message_send_ttl_seconds if message_send_ttl_seconds
        
        response = @client.request(:post, "#{business_account_id}/message_templates", 
                                   body: payload.to_json, response_type: :json)
        Types::TemplateCreateResponse.new(response)
      end

      # Update a template
      def update(business_account_id:, template_id:, category: nil, components: nil)
        payload = {}
        payload[:category] = category if category
        payload[:components] = normalize_components(components) if components
        
        return if payload.empty?
        
        response = @client.request(:post, "#{business_account_id}/message_templates/#{template_id}", 
                                   body: payload.to_json, response_type: :json)
        Types::GraphSuccessResponse.new(response)
      end

      # Delete a template
      def delete(business_account_id:, name: nil, template_id: nil, hsm_id: nil, language: nil)
        if template_id
          # Delete by template ID
          response = @client.request(:delete, "#{business_account_id}/message_templates/#{template_id}", 
                                     response_type: :json)
        elsif name
          # Delete by name and language
          query_params = { name: name }
          query_params[:language] = language if language
          query_params[:hsm_id] = hsm_id if hsm_id
          
          response = @client.request(:delete, "#{business_account_id}/message_templates", 
                                     query: query_params, response_type: :json)
        else
          raise ArgumentError, 'Must provide either template_id or name'
        end
        
        Types::GraphSuccessResponse.new(response)
      end

      # Template builder helpers
      def build_text_component(text:, example: nil)
        component = { type: 'BODY', text: text }
        component[:example] = example if example
        component
      end

      def build_header_component(type:, text: nil, image: nil, video: nil, 
                                 document: nil, example: nil)
        component = { type: 'HEADER', format: type.upcase }
        
        case type.upcase
        when 'TEXT'
          component[:text] = text if text
        when 'IMAGE'
          component[:example] = { header_handle: [image] } if image
        when 'VIDEO'
          component[:example] = { header_handle: [video] } if video
        when 'DOCUMENT'
          component[:example] = { header_handle: [document] } if document
        end
        
        component[:example] = example if example
        component
      end

      def build_footer_component(text: nil, code_expiration_minutes: nil)
        component = { type: 'FOOTER' }
        component[:text] = text if text
        component[:code_expiration_minutes] = code_expiration_minutes if code_expiration_minutes
        component
      end

      def build_buttons_component(buttons:)
        {
          type: 'BUTTONS',
          buttons: buttons.map { |btn| normalize_button(btn) }
        }
      end

      def build_button(type:, text: nil, url: nil, phone_number: nil, 
                       otp_type: nil, autofill_text: nil, package_name: nil, 
                       signature_hash: nil)
        button = { type: type.upcase }
        
        case type.upcase
        when 'QUICK_REPLY'
          button[:text] = text if text
        when 'URL'
          button[:text] = text if text
          button[:url] = url if url
        when 'PHONE_NUMBER'
          button[:text] = text if text
          button[:phone_number] = phone_number if phone_number
        when 'OTP'
          button[:otp_type] = otp_type if otp_type
          button[:text] = text if text
          button[:autofill_text] = autofill_text if autofill_text
          button[:package_name] = package_name if package_name
          button[:signature_hash] = signature_hash if signature_hash
        end
        
        button
      end

      # Authentication template builder
      def build_authentication_template(name:, language:, ttl_seconds: 60, 
                                        add_security_recommendation: true,
                                        code_expiration_minutes: 10,
                                        otp_type: 'COPY_CODE')
        components = []
        
        # Body component with security recommendation
        body_component = { type: 'BODY' }
        body_component[:add_security_recommendation] = add_security_recommendation
        components << body_component
        
        # Footer component with expiration
        if code_expiration_minutes
          components << build_footer_component(code_expiration_minutes: code_expiration_minutes)
        end
        
        # OTP button
        components << build_buttons_component(
          buttons: [build_button(type: 'OTP', otp_type: otp_type)]
        )
        
        {
          name: name,
          language: language,
          category: 'AUTHENTICATION',
          message_send_ttl_seconds: ttl_seconds,
          components: components
        }
      end

      # Marketing template builder
      def build_marketing_template(name:, language:, header: nil, body:, footer: nil, 
                                   buttons: nil, body_example: nil)
        components = []
        
        # Header component
        components << header if header
        
        # Body component
        body_component = build_text_component(text: body, example: body_example)
        components << body_component
        
        # Footer component
        components << build_footer_component(text: footer) if footer
        
        # Buttons component
        components << build_buttons_component(buttons: buttons) if buttons
        
        {
          name: name,
          language: language,
          category: 'MARKETING',
          components: components
        }
      end

      # Utility template builder
      def build_utility_template(name:, language:, body:, header: nil, footer: nil, 
                                 buttons: nil, body_example: nil)
        components = []
        
        # Header component
        components << header if header
        
        # Body component
        body_component = build_text_component(text: body, example: body_example)
        components << body_component
        
        # Footer component
        components << build_footer_component(text: footer) if footer
        
        # Buttons component
        components << build_buttons_component(buttons: buttons) if buttons
        
        {
          name: name,
          language: language,
          category: 'UTILITY',
          components: components
        }
      end

      private

      def validate_template_data(name:, language:, category:, components:)
        raise ArgumentError, 'Template name cannot be empty' if name.nil? || name.strip.empty?
        raise ArgumentError, 'Language cannot be empty' if language.nil? || language.strip.empty?
        raise ArgumentError, 'Category cannot be empty' if category.nil? || category.strip.empty?
        raise ArgumentError, 'Components cannot be empty' if components.nil? || components.empty?
        
        # Validate category
        valid_categories = Types::TEMPLATE_CATEGORIES
        unless valid_categories.include?(category.upcase)
          raise ArgumentError, "Invalid category '#{category}'. Must be one of: #{valid_categories.join(', ')}"
        end
        
        # Validate components structure
        components.each_with_index do |component, index|
          unless component.is_a?(Hash) && component[:type]
            raise ArgumentError, "Component at index #{index} must be a Hash with :type key"
          end
        end
      end

      def normalize_components(components)
        components.map { |component| normalize_component(component) }
      end

      def normalize_component(component)
        # Ensure component keys are strings for API compatibility
        normalized = {}
        component.each { |key, value| normalized[key.to_s] = value }
        normalized
      end

      def normalize_button(button)
        # Ensure button keys are strings for API compatibility
        normalized = {}
        button.each { |key, value| normalized[key.to_s] = value }
        normalized
      end
    end
  end
end