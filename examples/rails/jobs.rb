# frozen_string_literal: true

# Background jobs for WhatsApp message sending
# These jobs handle asynchronous message sending to improve performance

class SendWelcomeMessageJob < ApplicationJob
  queue_as :whatsapp_messages
  
  retry_on KapsoClientRuby::RateLimitError, wait: :exponentially_longer, attempts: 5
  retry_on KapsoClientRuby::TemporaryError, wait: 30.seconds, attempts: 3
  
  discard_on KapsoClientRuby::AuthenticationError
  discard_on KapsoClientRuby::ValidationError

  def perform(user)
    return unless user.phone_number.present?
    
    service = KapsoMessageService.new
    
    begin
      result = service.send_welcome_message(user)
      
      if result && result.dig('messages', 0, 'id')
        # Track the message
        WhatsappMessage.track_message(
          user: user,
          message_id: result.dig('messages', 0, 'id'),
          message_type: 'welcome',
          phone_number: user.phone_number,
          messageable: user
        )
        
        Rails.logger.info "Welcome message sent to user #{user.id}: #{result.dig('messages', 0, 'id')}"
      end
      
    rescue KapsoClientRuby::Error => e
      Rails.logger.error "Failed to send welcome message to user #{user.id}: #{e.message}"
      
      # Track failed message
      WhatsappMessage.create!(
        user: user,
        message_id: "failed_#{SecureRandom.hex(8)}",
        message_type: 'welcome',
        phone_number: user.phone_number,
        messageable: user,
        status: 'failed',
        error_message: e.message,
        sent_at: Time.current
      )
      
      raise # Re-raise to trigger retry logic
    end
  end
end

class SendOrderConfirmationJob < ApplicationJob
  queue_as :whatsapp_messages
  
  retry_on KapsoClientRuby::RateLimitError, wait: :exponentially_longer, attempts: 5
  retry_on KapsoClientRuby::TemporaryError, wait: 30.seconds, attempts: 3

  def perform(user, order)
    return unless user.phone_number.present?
    
    service = KapsoMessageService.new
    
    begin
      result = service.send_order_confirmation(order)
      
      if result && result.dig('messages', 0, 'id')
        WhatsappMessage.track_message(
          user: user,
          message_id: result.dig('messages', 0, 'id'),
          message_type: 'order_confirmation',
          phone_number: user.phone_number,
          messageable: order
        )
        
        Rails.logger.info "Order confirmation sent for order #{order.id}: #{result.dig('messages', 0, 'id')}"
      end
      
    rescue KapsoClientRuby::Error => e
      Rails.logger.error "Failed to send order confirmation for order #{order.id}: #{e.message}"
      raise
    end
  end
end

class SendOrderStatusUpdateJob < ApplicationJob
  queue_as :whatsapp_messages
  
  retry_on KapsoClientRuby::RateLimitError, wait: :exponentially_longer, attempts: 5

  def perform(user, order)
    return unless user.phone_number.present?
    
    # Don't spam users with too many updates
    return if user.received_message_type_recently?('order_status_update', within: 1.hour)
    
    service = KapsoClientRuby::Rails::Service.new
    
    begin
      # Use different templates based on order status
      template_name = case order.status
                     when 'confirmed' then 'order_confirmed'
                     when 'processing' then 'order_processing'  
                     when 'shipped' then 'order_shipped'
                     when 'delivered' then 'order_delivered'
                     when 'cancelled' then 'order_cancelled'
                     else 'order_status_update'
                     end
      
      components = build_order_status_components(order, user)
      
      result = service.send_template_message(
        to: user.phone_number,
        template_name: template_name,
        language: user.preferred_language || 'en',
        components: components
      )
      
      if result && result.dig('messages', 0, 'id')
        WhatsappMessage.track_message(
          user: user,
          message_id: result.dig('messages', 0, 'id'),
          message_type: 'order_status_update',
          phone_number: user.phone_number,
          messageable: order
        )
        
        Rails.logger.info "Order status update sent for order #{order.id}: #{order.status}"
      end
      
    rescue KapsoClientRuby::Error => e
      Rails.logger.error "Failed to send order status update for order #{order.id}: #{e.message}"
      raise
    end
  end

  private

  def build_order_status_components(order, user)
    [
      {
        type: 'body',
        parameters: [
          { type: 'text', text: user.first_name || 'Customer' },
          { type: 'text', text: order.id.to_s },
          { type: 'text', text: order.status.humanize },
          { type: 'text', text: order.formatted_total }
        ]
      }
    ].tap do |components|
      # Add tracking info for shipped orders
      if order.shipped? && order.tracking_number.present?
        components << {
          type: 'body',
          parameters: [
            { type: 'text', text: order.tracking_number }
          ]
        }
      end
    end
  end
end

class SendPhoneVerificationJob < ApplicationJob
  queue_as :whatsapp_messages
  
  retry_on KapsoClientRuby::Error, wait: 30.seconds, attempts: 3

  def perform(user)
    return unless user.phone_number.present?
    
    # Generate verification code
    verification_code = rand(100000..999999).to_s
    
    # Store verification code (you might use Redis or database)
    Rails.cache.write("phone_verification:#{user.id}", verification_code, expires_in: 10.minutes)
    
    service = KapsoClientRuby::Rails::Service.new
    
    begin
      result = service.send_template_message(
        to: user.phone_number,
        template_name: 'phone_verification',
        language: user.preferred_language || 'en',
        components: [
          {
            type: 'body',
            parameters: [
              { type: 'text', text: verification_code }
            ]
          }
        ]
      )
      
      if result && result.dig('messages', 0, 'id')
        WhatsappMessage.track_message(
          user: user,
          message_id: result.dig('messages', 0, 'id'),
          message_type: 'phone_verification',
          phone_number: user.phone_number,
          messageable: user
        )
        
        Rails.logger.info "Phone verification sent to user #{user.id}"
      end
      
    rescue KapsoClientRuby::Error => e
      Rails.logger.error "Failed to send phone verification to user #{user.id}: #{e.message}"
      raise
    end
  end
end

class SendNotificationJob < ApplicationJob
  queue_as :whatsapp_messages
  
  retry_on KapsoClientRuby::RateLimitError, wait: :exponentially_longer, attempts: 3

  def perform(user, message, message_type = 'general_notification')
    return unless user.phone_number.present? && user.notifications_enabled?
    
    service = KapsoMessageService.new
    
    begin
      result = service.send_text(
        phone_number: user.phone_number,
        message: message
      )
      
      if result && result.dig('messages', 0, 'id')
        WhatsappMessage.track_message(
          user: user,
          message_id: result.dig('messages', 0, 'id'),
          message_type: message_type,
          phone_number: user.phone_number
        )
        
        Rails.logger.info "Notification sent to user #{user.id}: #{message.truncate(50)}"
      end
      
    rescue KapsoClientRuby::Error => e
      Rails.logger.error "Failed to send notification to user #{user.id}: #{e.message}"
      raise
    end
  end
end

class SendBulkNotificationJob < ApplicationJob
  queue_as :bulk_whatsapp
  
  # Process users in batches to avoid overwhelming the API
  def perform(user_ids, message, message_type = 'marketing')
    User.where(id: user_ids).with_phone_number.opted_in_for_notifications.find_each(batch_size: 50) do |user|
      # Add delay between messages to respect rate limits
      SendNotificationJob.set(wait: rand(1..5).seconds).perform_later(user, message, message_type)
    end
  end
end

class HandleIncomingMessageJob < ApplicationJob
  queue_as :whatsapp_webhooks

  def perform(message_data)
    phone_number = message_data['from']
    message_text = message_data.dig('text', 'body')
    message_id = message_data['id']
    
    # Find user by phone number
    user = User.find_by(phone_number: phone_number)
    
    unless user
      Rails.logger.warn "Received message from unknown number: #{phone_number}"
      return
    end
    
    Rails.logger.info "Received message from user #{user.id}: #{message_text}"
    
    # Process the incoming message based on content
    case message_text&.downcase&.strip
    when 'stop', 'unsubscribe'
      handle_unsubscribe_request(user)
    when 'start', 'subscribe' 
      handle_subscribe_request(user)
    when 'help', 'menu'
      send_help_message(user)
    when 'status'
      send_account_status(user)
    else
      # Forward to customer service or handle as general inquiry
      handle_general_inquiry(user, message_text, message_id)
    end
  end

  private

  def handle_unsubscribe_request(user)
    user.update!(notifications_enabled: false)
    
    service = KapsoMessageService.new
    service.send_text(
      phone_number: user.phone_number,
      message: "You have been unsubscribed from notifications. Reply 'START' to re-enable."
    )
    
    Rails.logger.info "User #{user.id} unsubscribed from notifications"
  end

  def handle_subscribe_request(user)
    user.update!(notifications_enabled: true)
    
    service = KapsoMessageService.new
    service.send_text(
      phone_number: user.phone_number,
      message: "Welcome back! You'll now receive notifications. Reply 'STOP' to unsubscribe."
    )
    
    Rails.logger.info "User #{user.id} subscribed to notifications"
  end

  def send_help_message(user)
    help_text = <<~TEXT
      Available commands:
      • STOP - Unsubscribe from messages
      • START - Subscribe to messages  
      • STATUS - Check your account status
      • HELP - Show this menu
      
      For support, contact us at support@example.com
    TEXT
    
    service = KapsoMessageService.new
    service.send_text(phone_number: user.phone_number, message: help_text)
  end

  def send_account_status(user)
    recent_orders = user.orders.recent.limit(3)
    
    status_text = "Account Status:\n"
    status_text += "Name: #{user.name}\n"
    status_text += "Email: #{user.email}\n"
    status_text += "Recent orders: #{recent_orders.count}\n"
    
    if recent_orders.any?
      status_text += "\nLast order: ##{recent_orders.first.id} - #{recent_orders.first.status.humanize}"
    end
    
    service = KapsoMessageService.new
    service.send_text(phone_number: user.phone_number, message: status_text)
  end

  def handle_general_inquiry(user, message_text, message_id)
    # Create a support ticket or notification for customer service
    SupportTicket.create!(
      user: user,
      subject: "WhatsApp Inquiry",
      message: message_text,
      source: 'whatsapp',
      whatsapp_message_id: message_id
    )
    
    # Send auto-reply
    service = KapsoMessageService.new
    service.send_text(
      phone_number: user.phone_number,
      message: "Thanks for your message! Our team will get back to you soon. For urgent matters, call us at (555) 123-4567."
    )
    
    Rails.logger.info "Created support ticket for user #{user.id} from WhatsApp message"
  end
end

class UpdateMessageStatusJob < ApplicationJob
  queue_as :whatsapp_webhooks

  def perform(status_data)
    message_id = status_data['id']
    status = status_data['status']
    timestamp = status_data['timestamp']
    
    # Update message status in database
    WhatsappMessage.update_status_from_webhook(message_id, status, timestamp)
    
    Rails.logger.debug "Updated message #{message_id} status to #{status}"
  end
end