# frozen_string_literal: true

module KapsoClientRuby
  module Types
    # Message status types
    MESSAGE_STATUSES = %w[accepted held_for_quality_assessment].freeze

    # Template status types
    TEMPLATE_STATUSES = %w[APPROVED PENDING REJECTED PAUSED IN_APPEAL DISABLED].freeze

    # Template categories
    TEMPLATE_CATEGORIES = %w[MARKETING UTILITY AUTHENTICATION UNKNOWN].freeze

    # Media types
    MEDIA_TYPES = %w[image audio video document sticker].freeze

    # Interactive message types
    INTERACTIVE_TYPES = %w[button list product product_list flow address location_request call_permission].freeze

    # Message response structure
    class SendMessageResponse
      attr_reader :messaging_product, :contacts, :messages

      def initialize(data)
        @messaging_product = data['messaging_product']
        @contacts = data['contacts']&.map { |c| MessageContact.new(c) } || []
        @messages = data['messages']&.map { |m| MessageInfo.new(m) } || []
      end
    end

    class MessageContact
      attr_reader :input, :wa_id

      def initialize(data)
        @input = data['input']
        @wa_id = data['wa_id']
      end
    end

    class MessageInfo
      attr_reader :id, :message_status

      def initialize(data)
        @id = data['id']
        @message_status = data['message_status']
      end
    end

    # Media response structures
    class MediaUploadResponse
      attr_reader :id

      def initialize(data)
        @id = data['id']
      end
    end

    class MediaMetadataResponse
      attr_reader :messaging_product, :url, :mime_type, :sha256, :file_size, :id

      def initialize(data)
        @messaging_product = data['messaging_product']
        @url = data['url']
        @mime_type = data['mime_type']
        @sha256 = data['sha256']
        @file_size = data['file_size']
        @id = data['id']
      end
    end

    # Template structures
    class MessageTemplate
      attr_reader :id, :name, :category, :language, :status, :components, 
                  :quality_score_category, :warnings, :previous_category, 
                  :library_template_name, :last_updated_time

      def initialize(data)
        @id = data['id']
        @name = data['name']
        @category = data['category']
        @language = data['language']
        @status = data['status']
        @components = data['components']
        @quality_score_category = data['quality_score_category']
        @warnings = data['warnings']
        @previous_category = data['previous_category']
        @library_template_name = data['library_template_name']
        @last_updated_time = data['last_updated_time']
      end
    end

    class TemplateCreateResponse
      attr_reader :id, :status, :category

      def initialize(data)
        @id = data['id']
        @status = data['status']
        @category = data['category']
      end
    end

    # Paging structures
    class GraphPaging
      attr_reader :cursors, :next_page, :previous_page

      def initialize(data)
        @cursors = data['cursors'] || {}
        @next_page = data['next']
        @previous_page = data['previous']
      end

      def before
        cursors['before']
      end

      def after
        cursors['after']
      end
    end

    class PagedResponse
      attr_reader :data, :paging

      def initialize(data, item_class = nil)
        @data = if item_class && data['data'].is_a?(Array)
                  data['data'].map { |item| item_class.new(item) }
                else
                  data['data'] || []
                end
        @paging = GraphPaging.new(data['paging'] || {})
      end
    end

    # Success response
    class GraphSuccessResponse
      attr_reader :success

      def initialize(data = nil)
        @success = data.nil? || data['success'] || true
      end

      def success?
        @success
      end
    end

    # Business profile structures
    class BusinessProfileEntry
      attr_reader :about, :address, :description, :email, :websites, 
                  :vertical, :profile_picture_url, :profile_picture_handle

      def initialize(data)
        @about = data['about']
        @address = data['address']
        @description = data['description']
        @email = data['email']
        @websites = data['websites']
        @vertical = data['vertical']
        @profile_picture_url = data['profile_picture_url']
        @profile_picture_handle = data['profile_picture_handle']
      end
    end

    # Conversation structures
    class ConversationRecord
      attr_reader :id, :phone_number, :phone_number_id, :status, :last_active_at, 
                  :kapso, :metadata

      def initialize(data)
        @id = data['id']
        @phone_number = data['phone_number']
        @phone_number_id = data['phone_number_id']
        @status = data['status']
        @last_active_at = data['last_active_at']
        @kapso = data['kapso']
        @metadata = data['metadata']
      end
    end

    # Contact structures
    class ContactRecord
      attr_reader :wa_id, :phone_number, :profile_name, :metadata

      def initialize(data)
        @wa_id = data['wa_id']
        @phone_number = data['phone_number']
        @profile_name = data['profile_name']
        @metadata = data['metadata']
      end
    end

    # Call structures
    class CallRecord
      attr_reader :id, :direction, :status, :duration_seconds, :started_at, 
                  :ended_at, :whatsapp_conversation_id, :whatsapp_contact_id

      def initialize(data)
        @id = data['id']
        @direction = data['direction']
        @status = data['status']
        @duration_seconds = data['duration_seconds']
        @started_at = data['started_at']
        @ended_at = data['ended_at']
        @whatsapp_conversation_id = data['whatsapp_conversation_id']
        @whatsapp_contact_id = data['whatsapp_contact_id']
      end
    end

    class CallConnectResponse
      attr_reader :messaging_product, :calls

      def initialize(data)
        @messaging_product = data['messaging_product']
        @calls = data['calls'] || []
      end
    end

    class CallActionResponse < GraphSuccessResponse
      attr_reader :messaging_product

      def initialize(data)
        super(data)
        @messaging_product = data['messaging_product']
      end
    end

    # Utility method to convert snake_case to camelCase for API requests
    def self.to_camel_case(str)
      str.split('_').map.with_index { |word, i| i == 0 ? word : word.capitalize }.join
    end

    # Utility method to convert camelCase to snake_case for Ruby conventions
    def self.to_snake_case(str)
      str.gsub(/([A-Z])/, '_\1').downcase.sub(/^_/, '')
    end

    # Deep convert hash keys from camelCase to snake_case
    def self.deep_snake_case_keys(obj)
      case obj
      when Hash
        obj.transform_keys { |key| to_snake_case(key.to_s) }
           .transform_values { |value| deep_snake_case_keys(value) }
      when Array
        obj.map { |item| deep_snake_case_keys(item) }
      else
        obj
      end
    end

    # Deep convert hash keys from snake_case to camelCase
    def self.deep_camel_case_keys(obj)
      case obj
      when Hash
        obj.transform_keys { |key| to_camel_case(key.to_s) }
           .transform_values { |value| deep_camel_case_keys(value) }
      when Array
        obj.map { |item| deep_camel_case_keys(item) }
      else
        obj
      end
    end
  end
end