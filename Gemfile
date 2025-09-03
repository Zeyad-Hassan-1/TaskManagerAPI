source "https://rubygems.org"
gem "bcrypt", ">= 3.1.12"
gem "jwt", ">= 2.5"
gem "rack-cors", ">= 0"
gem "active_model_serializers", ">= 0.10.12"
gem "rswag"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.0.2", ">= 8.0.2.1"
# Use postgresql as the database for Active Record
gem "pg", "~> 1.6"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
# gem "jbuilder"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"
gem "jwt_rails_api_auth", "~> 1.0", ">= 1.0.3"
# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"
gem "rswag-api"
gem "rswag-ui"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "image_processing", "~> 1.2"

# Cloud Storage Support (install only what you need)
gem "aws-sdk-s3", "~> 1.0", require: false  # For Amazon S3
# gem "google-cloud-storage", "~> 1.0", require: false  # For Google Cloud Storage
# gem "azure-storage-blob", "~> 2.0", require: false  # For Azure Storage

# Production monitoring and error tracking (optional)
# gem "sentry-ruby", require: false
# gem "sentry-rails", require: false
# gem "newrelic_rpm", require: false

# Rate limiting and security
gem "rack-attack", require: false

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin Ajax possible
# gem "rack-cors"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "rspec-rails"
  gem "rswag-specs"
  gem "rspec-openapi"
  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false
  gem "annotate"
  gem "rails-erd"


  # Testing gems
  gem "factory_bot_rails", "~> 6.4"
  gem "faker", "~> 3.2"
  gem "shoulda-matchers", "~> 6.0"
end

group :test do
  gem "capybara", "~> 3.40"
  gem "selenium-webdriver", "~> 4.10"
  gem "webdrivers", "~> 5.3"
end

gem "letter_opener", "~> 1.10"  # For email preview in development
