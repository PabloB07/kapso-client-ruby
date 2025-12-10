# frozen_string_literal: true

# WhatsApp Flows API Examples
# Demonstrates Flow creation, deployment, messaging, and webhook handling

require 'kapso-client-ruby'
require 'dotenv'

Dotenv.load

# Initialize client
client = KapsoClientRuby::Client.new(
  access_token: ENV['WHATSAPP_ACCESS_TOKEN']
)

business_account_id = ENV['WHATSAPP_BUSINESS_ACCOUNT_ID']
phone_number_id = ENV['PHONE_NUMBER_ID']

# 1. CREATE A FLOW

puts "Creating a new Flow..."

flow = client.flows.create(
  business_account_id: business_account_id,
  name: 'appointment_booking',
  categories: ['APPOINTMENT_BOOKING'],
  endpoint_uri: 'https://your-server.com/whatsapp/flows'
)

puts "Flow created: #{flow['id']}"
flow_id = flow['id']

# 2. UPDATE FLOW ASSET (JSON Definition)

puts "Updating Flow JSON..."

flow_json = {
  version: '3.0',
  screens: [
    {
      id: 'APPOINTMENT_DETAILS',
      title: 'Book Appointment',
      data: {},
      layout: {
        type: 'SingleColumnLayout',
        children: [
          {
            type: 'Form',
            name: 'appointment_form',
            children: [
              {
                type: 'TextInput',
                name: 'customer_name',
                label: 'Full Name',
                required: true
              },
              {
                type: 'DatePicker',
                name: 'appointment_date',
                label: 'Preferred Date',
                required: true
              },
              {
                type: 'Dropdown',
                name: 'service_type',
                label: 'Service',
                required: true,
                data_source: ['Haircut', 'Coloring', 'Styling']
              },
              {
                type: 'Footer',
                label: 'Continue',
                on_click_action: {
                  name: 'complete',
                  payload: {
                    customer_name: '${form.customer_name}',
                    appointment_date: '${form.appointment_date}',
                    service_type: '${form.service_type}'
                  }
                }
              }
            ]
          }
        ]
      }
    }
  ]
}

asset_response = client.flows.update_asset(
  flow_id: flow_id,
  asset: flow_json
)

if asset_response.valid?
  puts "Flow asset updated successfully!"
else
  puts "Validation errors:"
  asset_response.errors.each { |err| puts "  - #{err}" }
end

# 3. PUBLISH FLOW

puts "Publishing Flow..."

client.flows.publish(flow_id: flow_id)
puts "Flow published!"

# 4. GET PREVIEW URL

preview = client.flows.preview(flow_id: flow_id)
puts "Preview URL: #{preview.preview_url}"
puts "Expires at: #{preview.expires_at}"

# 5. SEND FLOW MESSAGE

puts "Sending Flow message..."

# Generate unique flow token (use UUID or session ID)
require 'securerandom'
flow_token = SecureRandom.uuid

message_response = client.messages.send_flow(
  phone_number_id: phone_number_id,
  to: '+1234567890',
  flow_id: flow_id,
  flow_cta: 'Book Now',
  flow_token: flow_token,
  header: {
    type: 'text',
    text: 'Appointment Booking'
  },
  body_text: 'Book your appointment in just a few taps!',
  footer_text: 'Available slots fill up fast'
)

puts "Flow message sent! Message ID: #{message_response.messages.first.id}"

# 6. IDEMPOTENT DEPLOYMENT

puts "\n\nIdempotent deployment example..."

# This will create or update and publish the flow
deployment = client.flows.deploy(
  business_account_id: business_account_id,
  name: 'feedback_form',
  categories: ['SURVEY'],
  flow_json: {
    version: '3.0',
    screens: [
      {
        id: 'FEEDBACK',
        title: 'Feedback',
        data: {},
        layout: {
          type: 'SingleColumnLayout',
          children: [
            {
              type: 'Form',
              name: 'feedback_form',
              children: [
                {
                  type: 'TextArea',
                  name: 'comments',
                  label: 'Your Feedback',
                  required: true
                },
                {
                  type: 'RadioButtonsGroup',
                  name: 'rating',
                  label: 'Rating',
                  required: true,
                  data_source: ['1 - Poor', '2 - Fair', '3 - Good', '4 - Very Good', '5 - Excellent']
                },
                {
                  type: 'Footer',
                  label: 'Submit',
                  on_click_action: {
                    name: 'complete',
                    payload: {
                      comments: '${form.comments}',
                      rating: '${form.rating}'
                    }
                  }
                }
              ]
            }
          ]
        }
      }
    ]
  }
)

puts "Deployment complete: #{deployment[:message]}"
puts "Flow ID: #{deployment[:id]}"

# 7. LIST ALL FLOWS

puts "\n\nListing all Flows..."

flows_list = client.flows.list(business_account_id: business_account_id)
flows_list['data'].each do |flow|
  puts "- #{flow['name']} (#{flow['id']}) - Status: #{flow['status']}"
end

# 8. GET FLOW DETAILS

flow_details = client.flows.get(
  flow_id: flow_id,
  fields: ['id', 'name', 'status', 'categories', 'endpoint_uri']
)

puts "\n\nFlow Details:"
puts "  Name: #{flow_details.name}"
puts "  Status: #{flow_details.status}"
puts "  Categories: #{flow_details.categories.join(', ')}"
puts "  Endpoint: #{flow_details.endpoint_uri}"

# 9. WEBHOOK HANDLING - RECEIVE FLOW EVENT

# This would typically be in your webhook endpoint
def handle_flow_webhook(encrypted_request, client)
  # Load your private key (the public key should be registered with WhatsApp)
  private_key = OpenSSL::PKey::RSA.new(File.read('path/to/private_key.pem'), 'optional_passphrase')
  
  # Decrypt the incoming Flow event
  flow_event = client.flows.receive_flow_event(
    encrypted_request: encrypted_request,
    private_key: private_key
  )
  
  puts "Flow Event Received:"
  puts "  Version: #{flow_event.version}"
  puts "  Screen: #{flow_event.screen}"
  puts "  Action: #{flow_event.action}"
  puts "  Data: #{flow_event.data.inspect}"
  
  # Process the form data
  case flow_event.action
  when 'INIT'
    # Flow initialized - return initial screen data
    response_data = {
      version: flow_event.version,
      screen: 'APPOINTMENT_DETAILS',
      data: {
        available_dates: ['2024-01-15', '2024-01-16', '2024-01-17']
      }
    }
  when 'data_exchange'
    # User submitted form data - process and respond
    customer_name = flow_event.data['customer_name']
    appointment_date = flow_event.data['appointment_date']
    service_type = flow_event.data['service_type']
    
    # Save to database, send confirmation, etc.
    puts "Booking appointment for #{customer_name} on #{appointment_date}"
    
    response_data = {
      version: flow_event.version,
      screen: 'SUCCESS',
      data: {
        success: true,
        confirmation_number: "APT#{rand(10000..99999)}"
      }
    }
  else
    response_data = {
      version: flow_event.version,
      error_message: 'Unknown action'
    }
  end
  
  # Encrypt and return response
  encrypted_response = client.flows.respond_to_flow(
    response_data: response_data,
    private_key: private_key
  )
  
  encrypted_response
end

# 10. DOWNLOAD FLOW MEDIA

# If Flow contains media uploads (images, documents, etc.)
def download_flow_media_example(media_url, client)
  media_content = client.flows.download_flow_media(
    media_url: media_url
  )
  
  # Save to file
  File.write('uploaded_document.pdf', media_content)
  puts "Media downloaded and saved"
end

# 11. UPDATE FLOW

puts "\n\nUpdating Flow properties..."

client.flows.update(
  flow_id: flow_id,
  categories: ['APPOINTMENT_BOOKING', 'CUSTOMER_SUPPORT'],
  endpoint_uri: 'https://new-server.com/whatsapp/flows'
)

puts "Flow updated!"
puts "\n\nAll Flow examples completed!"
