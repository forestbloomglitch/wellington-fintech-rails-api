source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Using current Ruby version for compatibility
ruby "2.6.10"

# Core Rails API - compatible version
gem "rails", "~> 6.1.7"

# Database & Storage
gem "pg", "~> 1.1"           # PostgreSQL for production
gem "sqlite3", "~> 1.4", group: :development  # SQLite for development
gem "redis", "~> 4.0"        # Redis for caching and sessions

# Authentication & Security
gem "jwt", "~> 2.3"          # JSON Web Tokens
gem "bcrypt", "~> 3.1.7"     # Password hashing
gem "rack-cors"              # Cross-origin resource sharing

# Background Jobs
gem "sidekiq", "~> 6.0"      # Background job processing

# Financial & Compliance
gem "money-rails", "~> 1.12" # Money handling with proper precision
gem "chronic", "~> 0.10"     # Natural language date parsing

# NZ Specific Integrations
gem "faraday", "~> 1.0"      # HTTP client for banking APIs
gem "nokogiri", "~> 1.10"    # XML parsing for government APIs

# Performance & Monitoring
gem "bootsnap", ">= 1.4.4", require: false # Boot performance
gem "puma", "~> 5.0"         # High-performance web server

group :development, :test do
  gem "debug", platforms: %i[ mri mingw x64_mingw ]
  gem "rspec-rails", "~> 6.0"
  gem "factory_bot_rails"
  gem "faker"
  gem "webmock"              # HTTP request stubbing
  gem "vcr"                  # Record HTTP interactions
  gem "timecop"              # Time manipulation for tests
end

group :development do
  gem "listen", "~> 3.8"
  gem "spring"
  gem "rubocop-rails"
  gem "rubocop-rspec"
  gem "rubocop-performance"
  gem "brakeman"             # Security vulnerability scanner
  gem "bundler-audit"        # Dependency vulnerability checking
  gem "letter_opener"        # Email preview in development
end

group :test do
  gem "shoulda-matchers"
  gem "rspec-sidekiq"        # Sidekiq testing helpers
  gem "database_cleaner-active_record"
  gem "simplecov", require: false # Code coverage
end

group :production do
  gem "lograge"              # Structured logging
  gem "newrelic_rpm"         # Application monitoring
  gem "sentry-ruby"          # Error tracking
  gem "sentry-rails"         # Rails-specific error tracking
end

# Wellington Business Hours & Holidays
gem "business_time", "~> 0.13"   # Business day calculations
gem "holidays", "~> 8.7"         # Holiday calculations with NZ support