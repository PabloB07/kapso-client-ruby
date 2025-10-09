# frozen_string_literal: true

# Example Rails controller showing various WhatsApp integration patterns
class NotificationsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_phone_number, only: [:send_notification, :send_order_update]

  # GET /notifications
  # Show notification preferences and send test message
  def index
    @user = current_user
    @message_service = KapsoMessageService.new
    @templates = @message_service.list_templates&.dig('data') || []
  end

  # POST /notifications/test
  # Send a test message to the current user
  def send_test
    service = KapsoMessageService.new
    
    begin
      result = service.send_text(
        phone_number: current_user.phone_number,
        message: "Hello #{current_user.name}! This is a test message from #{Rails.application.class.name.deconstantize}."
      )
      
      if result
        flash[:success] = "Test message sent successfully! Message ID: #{result.dig('messages', 0, 'id')}"
      else
        flash[:error] = "Failed to send test message. Please check the logs."
      end
    rescue KapsoClientRuby::Error => e
      flash[:error] = "Error sending message: #{e.message}"
      Rails.logger.error "WhatsApp test message error: #{e.message}"
    end
    
    redirect_to notifications_path
  end

  # POST /notifications/welcome
  # Send welcome message using template
  def send_welcome
    service = KapsoMessageService.new
    
    begin
      result = service.send_welcome_message(current_user)
      
      if result
        flash[:success] = "Welcome message sent!"
        
        # Track the sent message
        current_user.whatsapp_messages.create!(
          message_id: result.dig('messages', 0, 'id'),
          message_type: 'welcome',
          status: 'sent',
          sent_at: Time.current
        )
      else
        flash[:error] = "Failed to send welcome message."
      end
    rescue KapsoClientRuby::Error => e
      flash[:error] = "Error: #{e.message}"
    end
    
    redirect_to notifications_path
  end

  # POST /notifications/custom
  # Send custom message with template
  def send_custom
    template_name = params[:template_name]
    custom_params = params[:template_params] || {}
    
    unless template_name.present?
      flash[:error] = "Please select a template"
      redirect_to notifications_path
      return
    end
    
    service = KapsoClientRuby::Rails::Service.new
    
    begin
      # Build template components from form params
      components = []
      
      if custom_params.present?
        body_params = custom_params.values.map do |param|
          { type: 'text', text: param.to_s }
        end
        
        components << {
          type: 'body',
          parameters: body_params
        } if body_params.any?
      end
      
      result = service.send_template_message(
        to: current_user.phone_number,
        template_name: template_name,
        language: current_user.preferred_language || 'en',
        components: components
      )
      
      flash[:success] = "Template message sent! ID: #{result.dig('messages', 0, 'id')}"
      
      # Log the message
      Rails.logger.info "Template '#{template_name}' sent to #{current_user.phone_number}"
      
    rescue KapsoClientRuby::Error => e
      flash[:error] = "Failed to send template: #{e.message}"
      Rails.logger.error "Template send error: #{e.message}"
    end
    
    redirect_to notifications_path
  end

  # POST /notifications/document
  # Send a document to the user
  def send_document
    document_url = params[:document_url]
    filename = params[:filename]
    caption = params[:caption]
    
    unless document_url.present?
      flash[:error] = "Document URL is required"
      redirect_to notifications_path
      return
    end
    
    service = KapsoMessageService.new
    
    begin
      result = service.send_document(
        phone_number: current_user.phone_number,
        document_url: document_url,
        filename: filename,
        caption: caption
      )
      
      flash[:success] = "Document sent successfully!"
      Rails.logger.info "Document sent to #{current_user.phone_number}: #{document_url}"
      
    rescue KapsoClientRuby::Error => e
      flash[:error] = "Failed to send document: #{e.message}"
    end
    
    redirect_to notifications_path
  end

  # GET /notifications/message_status/:message_id
  # Check status of a sent message
  def message_status
    message_id = params[:id]
    service = KapsoMessageService.new
    
    begin
      status = service.get_message_status(message_id)
      
      if status
        render json: {
          message_id: status['id'],
          status: status['status'],
          timestamp: status['timestamp'],
          recipient_id: status['recipient_id']
        }
      else
        render json: { error: 'Message not found' }, status: :not_found
      end
    rescue KapsoClientRuby::Error => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  # POST /notifications/bulk
  # Send bulk messages (should be queued in production)
  def send_bulk
    recipients = params[:recipients]&.split(',')&.map(&:strip) || []
    message = params[:message]
    
    if recipients.empty? || message.blank?
      flash[:error] = "Recipients and message are required"
      redirect_to notifications_path
      return
    end
    
    # In production, this should be done via background jobs
    successful_sends = 0
    failed_sends = 0
    
    recipients.each do |phone_number|
      begin
        service = KapsoMessageService.new
        result = service.send_text(phone_number: phone_number, message: message)
        
        if result
          successful_sends += 1
          Rails.logger.info "Bulk message sent to #{phone_number}"
        else
          failed_sends += 1
        end
        
        # Rate limiting - small delay between messages
        sleep(0.5)
        
      rescue KapsoClientRuby::Error => e
        failed_sends += 1
        Rails.logger.error "Bulk message failed for #{phone_number}: #{e.message}"
      end
    end
    
    flash[:success] = "Bulk send complete: #{successful_sends} sent, #{failed_sends} failed"
    redirect_to notifications_path
  end

  private

  def ensure_phone_number
    unless current_user.phone_number.present?
      flash[:error] = "Please add a phone number to your profile first"
      redirect_to edit_user_registration_path
    end
  end

  def notification_params
    params.permit(:message, :template_name, :document_url, :filename, :caption, :recipients, template_params: {})
  end
end