# Kapso API Ruby SDK

[![Gem Version](https://badge.fury.io/rb/whatsapp-cloud-api-ruby.svg)](https://badge.fury.io/rb/whatsapp-cloud-api-ruby)
[![Ruby](https://img.shields.io/badge/ruby-%3E%3D%202.7.0-red.svg)](https://www.ruby-lang.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A comprehensive Ruby client library for the [WhatsApp Business Cloud API](https://developers.facebook.com/docs/whatsapp/cloud-api/). This SDK provides a complete interface for sending messages, managing media, templates, and more, with built-in error handling, retry logic, and debug capabilities.

## Features

- 🚀 **Complete API Coverage**: All Kapso Cloud API endpoints supported
- 📱 **Rich Message Types**: Text, media, templates, interactive messages, and more
- 🔐 **Dual Authentication**: Meta Graph API and Kapso Proxy support
- 🛡️ **Smart Error Handling**: Comprehensive error categorization and retry logic
- 📊 **Advanced Features**: Message history, analytics, and contact management (via Kapso)
- 🔍 **Debug Support**: Detailed logging and request/response tracing
- 📚 **Type Safety**: Structured response objects and validation
- ⚡ **Performance**: HTTP connection pooling and efficient request handling
- 🛤️ **Rails Integration**: First-class Rails support with generators, service classes, and background jobs

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'kapso-client-api'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install kapso-client-api
```

### Rails Integration

For Rails applications, use the built-in generator to set up everything automatically:

```bash
rails generate kapso_client_ruby:install
```

This creates:
- Configuration initializer
- Webhook controller
- Service class for messaging
- Background job examples
- Routes for webhooks

See the [Rails Integration Guide](RAILS_INTEGRATION.md) for detailed Rails-specific documentation.

## Quick Start

### Basic Setup

```ruby
require 'kapso_client_api'

# Initialize client with Meta Graph API access token
client = KapsoClientRuby::Client.new(
  access_token: 'your_access_token'
)

# Send a text message
response = client.messages.send_text(
  phone_number_id: 'your_phone_number_id',
  to: '+1234567890',
  body: 'Hello from Ruby!'
)

puts "Message sent: #{response.messages.first.id}"
```

### Using Kapso Proxy (for enhanced features)

```ruby
# Initialize client with Kapso API key for enhanced features
kapso_client = KapsoClientRuby::Client.new(
  kapso_api_key: 'your_kapso_api_key',
  base_url: 'https://app.kapso.ai/api/meta'
)

# Access message history and analytics
messages = kapso_client.messages.query(
  phone_number_id: 'your_phone_number_id',
  direction: 'inbound',
  limit: 10
)
```

## API Reference

### Messages

Send various types of messages with the Messages resource:

#### Text Messages

```ruby
# Simple text message
client.messages.send_text(
  phone_number_id: 'phone_id',
  to: '+1234567890',
  body: 'Hello World!'
)

# Text with URL preview
client.messages.send_text(
  phone_number_id: 'phone_id',
  to: '+1234567890',
  body: 'Check this out: https://example.com',
  preview_url: true
)
```

#### Media Messages

```ruby
# Send image
client.messages.send_image(
  phone_number_id: 'phone_id',
  to: '+1234567890',
  image: {
    link: 'https://example.com/image.jpg',
    caption: 'Beautiful sunset'
  }
)

# Send document
client.messages.send_document(
  phone_number_id: 'phone_id',
  to: '+1234567890',
  document: {
    id: 'media_id', # or link: 'https://...'
    filename: 'report.pdf',
    caption: 'Monthly report'
  }
)

# Send audio
client.messages.send_audio(
  phone_number_id: 'phone_id',
  to: '+1234567890',
  audio: { id: 'audio_media_id' }
)

# Send video
client.messages.send_video(
  phone_number_id: 'phone_id',
  to: '+1234567890',
  video: {
    link: 'https://example.com/video.mp4',
    caption: 'Tutorial video'
  }
)
```

#### Interactive Messages

```ruby
# Button interactive message
client.messages.send_interactive_buttons(
  phone_number_id: 'phone_id',
  to: '+1234567890',
  body_text: 'Choose an option:',
  buttons: [
    {
      type: 'reply',
      reply: {
        id: 'option_1',
        title: 'Option 1'
      }
    },
    {
      type: 'reply',
      reply: {
        id: 'option_2',
        title: 'Option 2'
      }
    }
  ],
  header: {
    type: 'text',
    text: 'Menu'
  }
)

# List interactive message
client.messages.send_interactive_list(
  phone_number_id: 'phone_id',
  to: '+1234567890',
  body_text: 'Please select from the list:',
  button_text: 'View Options',
  sections: [
    {
      title: 'Section 1',
      rows: [
        {
          id: 'item_1',
          title: 'Item 1',
          description: 'Description 1'
        }
      ]
    }
  ]
)
```

#### Template Messages

```ruby
# Simple template
client.messages.send_template(
  phone_number_id: 'phone_id',
  to: '+1234567890',
  name: 'hello_world',
  language: 'en_US'
)

# Template with parameters
client.messages.send_template(
  phone_number_id: 'phone_id',
  to: '+1234567890',
  name: 'appointment_reminder',
  language: 'en_US',
  components: [
    {
      type: 'body',
      parameters: [
        { type: 'text', text: 'John Doe' },
        { type: 'text', text: 'Tomorrow at 2 PM' }
      ]
    }
  ]
)
```

#### Message Reactions

```ruby
# Add reaction
client.messages.send_reaction(
  phone_number_id: 'phone_id',
  to: '+1234567890',
  message_id: 'message_to_react_to',
  emoji: '👍'
)

# Remove reaction
client.messages.send_reaction(
  phone_number_id: 'phone_id',
  to: '+1234567890',
  message_id: 'message_to_react_to',
  emoji: nil
)
```

#### Message Status

```ruby
# Mark message as read
client.messages.mark_read(
  phone_number_id: 'phone_id',
  message_id: 'message_id'
)

# Send typing indicator
client.messages.send_typing_indicator(
  phone_number_id: 'phone_id',
  to: '+1234567890'
)
```

### Media Management

Handle media uploads, downloads, and management:

```ruby
# Upload media
upload_response = client.media.upload(
  phone_number_id: 'phone_id',
  type: 'image',
  file: '/path/to/image.jpg'
)

media_id = upload_response.id

# Get media metadata
metadata = client.media.get(media_id: media_id)
puts "File size: #{metadata.file_size} bytes"
puts "MIME type: #{metadata.mime_type}"

# Download media
content = client.media.download(
  media_id: media_id,
  as: :binary
)

# Save media to file
client.media.save_to_file(
  media_id: media_id,
  filepath: '/path/to/save/file.jpg'
)

# Delete media
client.media.delete(media_id: media_id)
```

### Template Management

Create, manage, and use message templates:

```ruby
# List templates
templates = client.templates.list(
  business_account_id: 'your_business_id',
  status: 'APPROVED'
)

# Create marketing template
template_data = client.templates.build_marketing_template(
  name: 'summer_sale',
  language: 'en_US',
  body: 'Hi {{1}}! Our summer sale is here with {{2}} off!',
  header: {
    type: 'HEADER',
    format: 'TEXT',
    text: 'Summer Sale 🌞'
  },
  footer: 'Limited time offer',
  buttons: [
    {
      type: 'URL',
      text: 'Shop Now',
      url: 'https://shop.example.com'
    }
  ],
  body_example: {
    body_text: [['John', '25%']]
  }
)

response = client.templates.create(
  business_account_id: 'your_business_id',
  **template_data
)

# Create authentication template
auth_template = client.templates.build_authentication_template(
  name: 'verify_code',
  language: 'en_US',
  ttl_seconds: 300
)

client.templates.create(
  business_account_id: 'your_business_id',
  **auth_template
)

# Delete template
client.templates.delete(
  business_account_id: 'your_business_id',
  name: 'old_template',
  language: 'en_US'
)
```

### Advanced Features (Kapso Proxy)

Access enhanced features with Kapso proxy:

```ruby
# Initialize Kapso client
kapso_client = KapsoClientRuby::Client.new(
  kapso_api_key: 'your_kapso_key',
  base_url: 'https://app.kapso.ai/api/meta'
)

# Message history
messages = kapso_client.messages.query(
  phone_number_id: 'phone_id',
  direction: 'inbound',
  since: '2024-01-01T00:00:00Z',
  limit: 50
)

# Conversation management
conversations = kapso_client.conversations.list(
  phone_number_id: 'phone_id',
  status: 'active'
)

conversation = kapso_client.conversations.get(
  conversation_id: conversations.data.first.id
)

# Update conversation status
kapso_client.conversations.update_status(
  conversation_id: conversation.id,
  status: 'archived'
)

# Contact management
contacts = kapso_client.contacts.list(
  phone_number_id: 'phone_id',
  limit: 100
)

# Update contact metadata
kapso_client.contacts.update(
  phone_number_id: 'phone_id',
  wa_id: 'contact_wa_id',
  metadata: {
    tags: ['premium', 'customer'],
    source: 'website'
  }
)

# Search contacts
results = kapso_client.contacts.search(
  phone_number_id: 'phone_id',
  query: 'john',
  search_in: ['profile_name', 'phone_number']
)
```

## Configuration

### Global Configuration

```ruby
KapsoClientRuby.configure do |config|
  config.debug = true
  config.timeout = 60
  config.open_timeout = 10
  config.max_retries = 3
  config.retry_delay = 1.0
end
```

### Client Configuration

```ruby
client = KapsoClientRuby::Client.new(
  access_token: 'token',
  debug: true,
  timeout: 30,
  logger: Logger.new('whatsapp.log')
)
```

### Debug Logging

Enable debug logging to see detailed HTTP requests and responses:

```ruby
# Enable debug mode
client = KapsoClientRuby::Client.new(
  access_token: 'token',
  debug: true
)

# Custom logger
logger = Logger.new(STDOUT)
logger.level = Logger::DEBUG

client = KapsoClientRuby::Client.new(
  access_token: 'token',
  logger: logger
)
```

## Error Handling

The SDK provides comprehensive error handling with detailed categorization:

```ruby
begin
  client.messages.send_text(
    phone_number_id: 'phone_id',
    to: 'invalid_number',
    body: 'Test'
  )
rescue KapsoClientRuby::Errors::GraphApiError => e
  puts "Error: #{e.message}"
  puts "Category: #{e.category}"
  puts "HTTP Status: #{e.http_status}"
  puts "Code: #{e.code}"
  
  # Check error type
  case e.category
  when :authorization
    puts "Authentication failed - check your access token"
  when :parameter
    puts "Invalid parameter - check phone number format"
  when :throttling
    puts "Rate limited - wait before retrying"
    if e.retry_hint[:retry_after_ms]
      sleep(e.retry_hint[:retry_after_ms] / 1000.0)
    end
  when :template
    puts "Template error - check template name and parameters"
  when :media
    puts "Media error - check file format and size"
  end
  
  # Check retry recommendations
  case e.retry_hint[:action]
  when :retry
    puts "Safe to retry this request"
  when :retry_after
    puts "Retry after specified delay: #{e.retry_hint[:retry_after_ms]}ms"
  when :do_not_retry
    puts "Do not retry - permanent error"
  when :fix_and_retry
    puts "Fix the request and retry"
  when :refresh_token
    puts "Access token needs to be refreshed"
  end
end
```

### Error Categories

- `:authorization` - Authentication and token errors
- `:permission` - Permission and access errors  
- `:parameter` - Invalid parameters or format errors
- `:throttling` - Rate limiting errors
- `:template` - Template-related errors
- `:media` - Media upload/download errors
- `:phone_registration` - Phone number registration errors
- `:integrity` - Message integrity errors
- `:business_eligibility` - Business account eligibility errors
- `:reengagement_window` - 24-hour messaging window errors
- `:waba_config` - WhatsApp Business Account configuration errors
- `:flow` - WhatsApp Flow errors
- `:synchronization` - Data synchronization errors
- `:server` - Server-side errors
- `:unknown` - Unclassified errors

### Automatic Retry Logic

```ruby
def send_with_retry(client, max_retries = 3)
  retries = 0
  
  begin
    client.messages.send_text(
      phone_number_id: 'phone_id',
      to: '+1234567890',
      body: 'Test message'
    )
  rescue KapsoClientRuby::Errors::GraphApiError => e
    retries += 1
    
    case e.retry_hint[:action]
    when :retry
      if retries <= max_retries
        sleep(retries * 2) # Exponential backoff
        retry
      end
    when :retry_after
      if e.retry_hint[:retry_after_ms] && retries <= max_retries
        sleep(e.retry_hint[:retry_after_ms] / 1000.0)
        retry
      end
    end
    
    raise # Re-raise if no retry
  end
end
```

## Webhook Handling

Handle incoming webhooks from WhatsApp:

```ruby
# Verify webhook signature
def verify_webhook_signature(payload, signature, app_secret)
  require 'openssl'
  
  sig_hash = signature.sub('sha256=', '')
  expected_sig = OpenSSL::HMAC.hexdigest('sha256', app_secret, payload)
  
  sig_hash == expected_sig
end

# In your webhook endpoint
def handle_webhook(request)
  payload = request.body.read
  signature = request.headers['X-Hub-Signature-256']
  
  unless verify_webhook_signature(payload, signature, ENV['WHATSAPP_APP_SECRET'])
    return [401, {}, ['Unauthorized']]
  end
  
  webhook_data = JSON.parse(payload)
  
  # Process webhook data
  webhook_data['entry'].each do |entry|
    entry['changes'].each do |change|
      if change['field'] == 'messages'
        messages = change['value']['messages'] || []
        messages.each do |message|
          handle_incoming_message(message)
        end
      end
    end
  end
  
  [200, {}, ['OK']]
end

def handle_incoming_message(message)
  case message['type']
  when 'text'
    puts "Received text: #{message['text']['body']}"
  when 'image'
    puts "Received image: #{message['image']['id']}"
  when 'interactive'
    puts "Received interactive response: #{message['interactive']}"
  end
end
```

## Testing

Run the test suite:

```bash
# Install development dependencies
bundle install

# Run tests
bundle exec rspec

# Run tests with coverage
bundle exec rspec --format documentation

# Run rubocop for style checking
bundle exec rubocop
```

### Testing with VCR

The SDK includes VCR cassettes for testing without making real API calls:

```ruby
# spec/spec_helper.rb
require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = 'spec/vcr_cassettes'
  config.hook_into :webmock
  config.configure_rspec_metadata!
  
  # Filter sensitive data
  config.filter_sensitive_data('<ACCESS_TOKEN>') { ENV['WHATSAPP_ACCESS_TOKEN'] }
  config.filter_sensitive_data('<PHONE_NUMBER_ID>') { ENV['PHONE_NUMBER_ID'] }
end

# In your tests
RSpec.describe 'Messages' do
  it 'sends text message', :vcr do
    client = KapsoClientRuby::Client.new(access_token: 'test_token')
    
    response = client.messages.send_text(
      phone_number_id: 'test_phone_id',
      to: '+1234567890',
      body: 'Test message'
    )
    
    expect(response.messages.first.id).to be_present
  end
end
```

## Examples

See the [examples](examples/) directory for comprehensive usage examples:

- [Basic Messaging](examples/basic_messaging.rb) - Text, media, and template messages
- [Media Management](examples/media_management.rb) - Upload, download, and manage media
- [Template Management](examples/template_management.rb) - Create and manage templates
- [Advanced Features](examples/advanced_features.rb) - Kapso proxy features and analytics

## Requirements

- Ruby >= 2.7.0
- Faraday >= 2.0
- A WhatsApp Business Account with Cloud API access
- Valid access token from Meta or Kapso API key

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/gokapso/whatsapp-cloud-api-ruby.

### Development Setup

```bash
git clone https://github.com/gokapso/whatsapp-cloud-api-ruby.git
cd whatsapp-cloud-api-ruby
bundle install
```

### Running Tests

```bash
# Run all tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/client_spec.rb

# Run with coverage
COVERAGE=true bundle exec rspec
```

### Code Style

```bash
# Check style
bundle exec rubocop

# Auto-fix issues
bundle exec rubocop -A
```

## License

This gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Support

- 📖 [WhatsApp Cloud API Documentation](https://developers.facebook.com/docs/whatsapp/cloud-api/)
- 🌐 [Kapso Platform](https://kapso.ai/) for enhanced features
- 🐛 [Issue Tracker](https://github.com/PabloB07/whatsapp-cloud-api-ruby/issues)
- 📧 Email: support@kapso.ai

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and updates.

---

Built with ❤️ for the [Kapso](https://kapso.ai) team