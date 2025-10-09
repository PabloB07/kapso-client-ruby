# Rails Integration Guide

This guide shows you how to integrate KapsoClientRuby with your Rails application for sending WhatsApp messages through the Kapso API.

## Installation

Add the gem to your Gemfile:

```ruby
gem 'kapso-client-ruby'
```

Then run:

```bash
bundle install
```

## Quick Setup with Generator

The easiest way to set up KapsoClientRuby in your Rails app is using the built-in generator:

```bash
rails generate kapso_client_ruby:install
```

This will create:
- `config/initializers/kapso_client_ruby.rb` - Configuration file
- `app/controllers/kapso_webhooks_controller.rb` - Webhook handler
- `app/services/kapso_message_service.rb` - Service class for messaging
- `.env.example.kapso` - Environment variables template
- Webhook routes in `config/routes.rb`

## Manual Setup

If you prefer to set up manually:

### 1. Configuration

Create `config/initializers/kapso_client_ruby.rb`:

```ruby
KapsoClientRuby.configure do |config|
  config.api_key = ENV['KAPSO_API_KEY']
  config.phone_number_id = ENV['KAPSO_PHONE_NUMBER_ID']
  config.business_account_id = ENV['KAPSO_BUSINESS_ACCOUNT_ID']
  
  # Optional settings
  config.debug = Rails.env.development?
  config.logger = Rails.logger
  config.timeout = 30
end
```

### 2. Environment Variables

Add to your `.env` file:

```bash
KAPSO_API_KEY=your_api_key_here
KAPSO_PHONE_NUMBER_ID=your_phone_number_id_here
KAPSO_BUSINESS_ACCOUNT_ID=your_business_account_id_here
```

### 3. Service Class

Create `app/services/kapso_message_service.rb`:

```ruby
class KapsoMessageService
  def initialize
    @service = KapsoClientRuby::Rails::Service.new
  end

  def send_welcome_message(user)
    @service.send_template_message(
      to: user.phone_number,
      template_name: 'welcome_message',
      language: 'en',
      components: [
        {
          type: 'body',
          parameters: [
            { type: 'text', text: user.first_name }
          ]
        }
      ]
    )
  end
end
```

## Usage Examples

### Sending Messages in Controllers

```ruby
class UsersController < ApplicationController
  def create
    @user = User.new(user_params)
    
    if @user.save
      # Send welcome message
      KapsoMessageService.new.send_welcome_message(@user)
      redirect_to @user, notice: 'User created and welcome message sent!'
    else
      render :new
    end
  end
end
```

### Using in Models

```ruby
class Order < ApplicationRecord
  belongs_to :user
  
  after_create :send_confirmation_message
  
  private
  
  def send_confirmation_message
    return unless user.phone_number.present?
    
    KapsoMessageService.new.send_order_confirmation(self)
  rescue KapsoClientRuby::Error => e
    Rails.logger.error "Failed to send order confirmation: #{e.message}"
  end
end
```

### Background Jobs

For better performance, send messages in background jobs:

```ruby
class SendWhatsAppMessageJob < ApplicationJob
  queue_as :default
  
  def perform(phone_number, message_type, **options)
    service = KapsoMessageService.new
    
    case message_type
    when 'welcome'
      service.send_welcome_message(options[:user])
    when 'order_confirmation'
      service.send_order_confirmation(options[:order])
    end
  end
end

# Usage in controller:
SendWhatsAppMessageJob.perform_later(user.phone_number, 'welcome', user: user)
```

## Webhook Integration

### 1. Webhook Controller

The generated webhook controller handles incoming WhatsApp messages and status updates:

```ruby
class KapsoWebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def verify
    # Webhook verification logic
  end

  def create
    service = KapsoClientRuby::Rails::Service.new
    service.process_webhook(params.to_unsafe_h)
    render json: { status: 'ok' }
  end
end
```

### 2. Routes

Add to `config/routes.rb`:

```ruby
post '/webhooks/kapso', to: 'kapso_webhooks#create'
get '/webhooks/kapso', to: 'kapso_webhooks#verify'
```

### 3. Event Listeners

Subscribe to WhatsApp events in your initializer:

```ruby
# In config/initializers/kapso_client_ruby.rb

ActiveSupport::Notifications.subscribe('kapso.message_received') do |name, start, finish, id, payload|
  message = payload[:message]
  
  # Handle incoming message
  HandleIncomingMessageJob.perform_later(message)
end

ActiveSupport::Notifications.subscribe('kapso.message_status_updated') do |name, start, finish, id, payload|
  status = payload[:status]
  
  # Update message status in database
  UpdateMessageStatusJob.perform_later(status)
end
```

## Available Rake Tasks

```bash
# Test configuration and send test message
rails kapso:test

# List available templates
rails kapso:templates

# Check message status
rails kapso:message_status[message_id]

# Validate webhook configuration
rails kapso:validate_webhook

# Generate sample .env file
rails kapso:sample_env
```

## Configuration Options

All configuration options available in the Rails initializer:

```ruby
KapsoClientRuby.configure do |config|
  # Required
  config.api_key = ENV['KAPSO_API_KEY']
  config.phone_number_id = ENV['KAPSO_PHONE_NUMBER_ID']
  config.business_account_id = ENV['KAPSO_BUSINESS_ACCOUNT_ID']
  
  # API Configuration
  config.api_host = ENV.fetch('KAPSO_API_HOST', 'https://graph.facebook.com')
  config.api_version = ENV.fetch('KAPSO_API_VERSION', 'v18.0')
  config.timeout = ENV.fetch('KAPSO_TIMEOUT', 30).to_i
  
  # Logging and Debug
  config.debug = Rails.env.development?
  config.logger = Rails.logger
  
  # Retry Configuration
  config.retry_on_failure = true
  config.max_retries = 3
end
```

## Rails-Specific Features

### 1. ActiveSupport Notifications

The gem automatically publishes events that you can subscribe to:

- `kapso.message_received` - When a WhatsApp message is received
- `kapso.message_status_updated` - When message delivery status changes
- `kapso.template_status_updated` - When template approval status changes

### 2. Rails Logger Integration

All Kapso operations automatically log to Rails.logger with appropriate log levels.

### 3. Environment-Based Configuration

The gem respects Rails environments and can be configured differently for development, test, and production.

### 4. Rails Service Pattern

The `KapsoClientRuby::Rails::Service` class follows Rails service object patterns and integrates seamlessly with Rails applications.

## Testing

### RSpec Integration

```ruby
# spec/rails_helper.rb
RSpec.configure do |config|
  config.before(:each) do
    # Mock Kapso API calls in tests
    allow_any_instance_of(KapsoClientRuby::Client).to receive(:send_request)
      .and_return({ 'messages' => [{ 'id' => 'test_message_id' }] })
  end
end

# spec/services/kapso_message_service_spec.rb
RSpec.describe KapsoMessageService do
  let(:user) { create(:user, phone_number: '+1234567890') }
  let(:service) { described_class.new }
  
  describe '#send_welcome_message' do
    it 'sends a welcome message to the user' do
      expect(service).to receive(:send_template_message)
        .with(hash_including(to: user.phone_number))
      
      service.send_welcome_message(user)
    end
  end
end
```

### Test Configuration

```ruby
# config/environments/test.rb
config.kapso.debug = false
config.kapso.logger = Logger.new('/dev/null') # Silence logs in tests
```

## Error Handling

```ruby
class KapsoMessageService
  def send_message_with_retry(phone_number, message)
    retries = 0
    max_retries = 3
    
    begin
      send_text_message(to: phone_number, text: message)
    rescue KapsoClientRuby::RateLimitError => e
      if retries < max_retries
        retries += 1
        sleep(2 ** retries) # Exponential backoff
        retry
      else
        Rails.logger.error "Rate limit exceeded after #{max_retries} retries: #{e.message}"
        raise
      end
    rescue KapsoClientRuby::Error => e
      Rails.logger.error "Kapso API error: #{e.message}"
      # Handle gracefully or re-raise depending on your needs
      nil
    end
  end
end
```

## Production Considerations

### 1. Environment Variables

Use Rails credentials or a secure environment variable management system:

```bash
# Using Rails credentials
rails credentials:edit

# Add:
kapso:
  api_key: your_actual_api_key
  phone_number_id: your_phone_number_id
  business_account_id: your_business_account_id
```

```ruby
# In initializer
config.api_key = Rails.application.credentials.dig(:kapso, :api_key)
```

### 2. Background Processing

Always use background jobs for message sending in production:

```ruby
class User < ApplicationRecord
  after_create :send_welcome_message_async
  
  private
  
  def send_welcome_message_async
    SendWelcomeMessageJob.perform_later(self)
  end
end
```

### 3. Rate Limiting

Implement rate limiting to avoid hitting API limits:

```ruby
class KapsoMessageService
  include ActionController::Helpers
  
  def send_message(phone_number, message)
    # Check rate limit before sending
    cache_key = "kapso_rate_limit:#{phone_number}"
    
    if Rails.cache.read(cache_key).to_i >= 10 # 10 messages per hour
      raise "Rate limit exceeded for #{phone_number}"
    end
    
    result = @service.send_text_message(to: phone_number, text: message)
    
    # Increment counter
    Rails.cache.increment(cache_key, 1, expires_in: 1.hour)
    
    result
  end
end
```

### 4. Monitoring and Alerting

```ruby
# In initializer, add error tracking
ActiveSupport::Notifications.subscribe('kapso.error') do |name, start, finish, id, payload|
  error = payload[:error]
  
  # Send to error tracking service
  Bugsnag.notify(error) if defined?(Bugsnag)
  Sentry.capture_exception(error) if defined?(Sentry)
end
```

## Troubleshooting

### Common Issues

1. **Invalid Phone Number Format**
   ```ruby
   # Ensure phone numbers are in E.164 format
   phone_number = "+1#{user.phone.gsub(/\D/, '')}"
   ```

2. **Missing Template Components**
   ```ruby
   # Always include required template parameters
   components = [
     {
       type: 'body',
       parameters: [
         { type: 'text', text: user.name }
       ]
     }
   ]
   ```

3. **Webhook Verification Failures**
   ```ruby
   # Make sure webhook verification token matches
   verify_token = params['hub.verify_token']
   expected_token = ENV['KAPSO_WEBHOOK_VERIFY_TOKEN']
   ```

### Debug Mode

Enable debug mode in development:

```ruby
# config/environments/development.rb
config.kapso.debug = true
```

This will log all API requests and responses to help with debugging.

## Support

For issues specific to Rails integration, please check:

1. Rails logs for detailed error messages
2. Kapso API documentation
3. GitHub issues: https://github.com/PabloB07/kapso-client-ruby/issues

## Contributing

To contribute to Rails integration features:

1. Fork the repository
2. Create a feature branch
3. Add tests for Rails-specific functionality
4. Submit a pull request

The Rails integration code is located in `lib/kapso_client_ruby/rails/`.