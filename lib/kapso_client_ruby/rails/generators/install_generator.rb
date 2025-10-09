# frozen_string_literal: true

require 'rails/generators'

module KapsoClientRuby
  module Rails
    module Generators
      class InstallGenerator < ::Rails::Generators::Base
        source_root File.expand_path('templates', __dir__)

        desc 'Install KapsoClientRuby in a Rails application'

        def create_initializer
          template 'initializer.rb.erb', 'config/initializers/kapso_client_ruby.rb'
        end

        def create_env_example
          template 'env.erb', '.env.example'
        end

        def create_webhook_controller
          template 'webhook_controller.rb.erb', 'app/controllers/kapso_webhooks_controller.rb'
        end

        def create_service_example
          template 'message_service.rb.erb', 'app/services/kapso_message_service.rb'
        end

        def add_routes
          route <<~RUBY
            # Kapso webhook endpoint
            post '/webhooks/kapso', to: 'kapso_webhooks#create'
            get '/webhooks/kapso', to: 'kapso_webhooks#verify' # For webhook verification
          RUBY
        end

        def show_readme
          say <<~MESSAGE

            KapsoClientRuby has been successfully installed!

            Next steps:
            1. Add your Kapso credentials to your environment variables:
               - KAPSO_API_KEY
               - KAPSO_PHONE_NUMBER_ID
               - KAPSO_BUSINESS_ACCOUNT_ID

            2. Review and customize the generated files:
               - config/initializers/kapso_client_ruby.rb
               - app/controllers/kapso_webhooks_controller.rb
               - app/services/kapso_message_service.rb

            3. Set up your webhook URL in the Kapso dashboard:
               https://yourapp.com/webhooks/kapso

            4. Test the integration:
               rails runner "KapsoMessageService.new.send_test_message"

            For more information, see: https://github.com/PabloB07/kapso-client-ruby

          MESSAGE
        end

        private

        def application_name
          if defined?(Rails) && Rails.application
            Rails.application.class.name.split('::').first
          else
            'YourApp'
          end
        end
      end
    end
  end
end