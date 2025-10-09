# frozen_string_literal: true

# Example Rails model integration showing WhatsApp messaging hooks
class User < ApplicationRecord
  has_many :orders, dependent: :destroy
  has_many :whatsapp_messages, dependent: :destroy

  # Validations
  validates :email, presence: true, uniqueness: true
  validates :phone_number, format: { with: /\A\+\d{10,15}\z/, message: "must be in E.164 format" }, allow_blank: true
  validates :preferred_language, inclusion: { in: %w[en es fr], message: "must be a supported language" }

  # Callbacks for WhatsApp integration
  after_create :send_welcome_message, if: :phone_number?
  after_update :send_phone_verification, if: :phone_number_changed?

  # Scopes
  scope :with_phone_number, -> { where.not(phone_number: nil) }
  scope :opted_in_for_notifications, -> { where(notifications_enabled: true) }

  # Instance methods
  
  def send_welcome_message
    SendWelcomeMessageJob.perform_later(self)
  end

  def send_phone_verification
    return unless phone_number.present?
    
    SendPhoneVerificationJob.perform_later(self)
  end

  def send_notification(message, type: 'general')
    return unless phone_number.present? && notifications_enabled?
    
    SendNotificationJob.perform_later(self, message, type)
  end

  def send_order_confirmation(order)
    return unless phone_number.present?
    
    SendOrderConfirmationJob.perform_later(self, order)
  end

  # Format phone number for WhatsApp (ensure E.164 format)
  def formatted_phone_number
    return nil unless phone_number.present?
    
    # Remove any non-digit characters except the leading +
    cleaned = phone_number.gsub(/[^\d+]/, '')
    
    # Ensure it starts with +
    cleaned.start_with?('+') ? cleaned : "+#{cleaned}"
  end

  # Check if user can receive WhatsApp messages
  def can_receive_whatsapp?
    phone_number.present? && notifications_enabled?
  end

  # Get recent WhatsApp messages
  def recent_whatsapp_messages(limit = 10)
    whatsapp_messages.order(created_at: :desc).limit(limit)
  end

  # Check if user has received a specific message type recently
  def received_message_type_recently?(message_type, within: 24.hours)
    whatsapp_messages
      .where(message_type: message_type)
      .where('created_at > ?', within.ago)
      .exists?
  end

  private

  def phone_number_changed?
    saved_change_to_phone_number? && phone_number.present?
  end
end

# Example Order model with WhatsApp integration
class Order < ApplicationRecord
  belongs_to :user
  has_many :order_items, dependent: :destroy
  has_many :whatsapp_messages, through: :user

  # Order statuses
  enum status: {
    pending: 0,
    confirmed: 1,
    processing: 2,
    shipped: 3,
    delivered: 4,
    cancelled: 5
  }

  # Callbacks for WhatsApp notifications
  after_create :send_order_confirmation
  after_update :send_status_update, if: :saved_change_to_status?

  # Instance methods

  def send_order_confirmation
    return unless user.can_receive_whatsapp?
    
    SendOrderConfirmationJob.perform_later(user, self)
  end

  def send_status_update
    return unless user.can_receive_whatsapp?
    
    # Don't send updates for pending status (already sent confirmation)
    return if status == 'pending'
    
    SendOrderStatusUpdateJob.perform_later(user, self)
  end

  def total_amount_in_cents
    (total_amount * 100).to_i
  end

  def formatted_total
    "$#{'%.2f' % total_amount}"
  end

  def estimated_delivery_date
    return nil unless shipped?
    
    shipped_at + 3.days # Example: 3 days for delivery
  end
end

# Example WhatsAppMessage model for tracking sent messages
class WhatsappMessage < ApplicationRecord
  belongs_to :user
  belongs_to :messageable, polymorphic: true, optional: true # Could be Order, User, etc.

  # Message types
  enum message_type: {
    welcome: 0,
    order_confirmation: 1,
    order_status_update: 2,
    phone_verification: 3,
    general_notification: 4,
    marketing: 5,
    support: 6
  }

  # Message status from WhatsApp API
  enum status: {
    sent: 0,
    delivered: 1,
    read: 2,
    failed: 3
  }

  # Validations
  validates :message_id, presence: true, uniqueness: true
  validates :phone_number, presence: true
  validates :message_type, presence: true

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :successful, -> { where(status: [:sent, :delivered, :read]) }
  scope :failed, -> { where(status: :failed) }

  # Class methods

  def self.track_message(user:, message_id:, message_type:, phone_number:, messageable: nil)
    create!(
      user: user,
      message_id: message_id,
      message_type: message_type,
      phone_number: phone_number,
      messageable: messageable,
      status: :sent,
      sent_at: Time.current
    )
  end

  def self.update_status_from_webhook(message_id, new_status, timestamp = nil)
    message = find_by(message_id: message_id)
    return unless message

    status_mapping = {
      'sent' => :sent,
      'delivered' => :delivered,
      'read' => :read,
      'failed' => :failed
    }

    mapped_status = status_mapping[new_status.to_s.downcase]
    return unless mapped_status

    message.update!(
      status: mapped_status,
      status_updated_at: timestamp ? Time.at(timestamp) : Time.current
    )
  end

  # Instance methods

  def delivered?
    %w[delivered read].include?(status)
  end

  def failed?
    status == 'failed'
  end

  def delivery_time
    return nil unless delivered? && sent_at.present? && status_updated_at.present?
    
    status_updated_at - sent_at
  end
end

# Example migration for WhatsApp messages tracking
# 
# class CreateWhatsappMessages < ActiveRecord::Migration[8.0]
#   def change
#     create_table :whatsapp_messages do |t|
#       t.references :user, null: false, foreign_key: true
#       t.references :messageable, polymorphic: true, null: true
#       t.string :message_id, null: false, index: { unique: true }
#       t.string :phone_number, null: false
#       t.integer :message_type, null: false
#       t.integer :status, default: 0
#       t.datetime :sent_at
#       t.datetime :status_updated_at
#       t.text :error_message
#       t.json :metadata # Store additional message data
#       
#       t.timestamps
#     end
#     
#     add_index :whatsapp_messages, [:user_id, :message_type]
#     add_index :whatsapp_messages, [:message_type, :status]
#   end
# end