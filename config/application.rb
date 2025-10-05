require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_mailbox/engine"
require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
# require "sprockets/railtie"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module WellingtonFintechRailsApi
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.1

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    config.time_zone = 'Auckland'

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    # CORS configuration for API
    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins '*' # Configure this for production
        resource '*',
          headers: :any,
          methods: [:get, :post, :put, :patch, :delete, :options, :head]
      end
    end

    # NZ-specific configuration
    config.active_record.default_timezone = :local
    config.i18n.default_locale = :en
    
    # Financial compliance settings
    config.x.audit_retention_period = 7.years # RBNZ requirement
    config.x.financial_precision = 2 # Decimal places for currency
    config.x.supported_currencies = %w[NZD AUD USD GBP EUR]
    
    # API versioning
    config.x.api_version = 'v1'
    config.x.api_base_url = '/api/v1'
  end
end