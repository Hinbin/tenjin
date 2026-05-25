# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "~> 2.7.1"

# Sets environment variables
gem "dotenv-rails", groups: [:development, :test]
gem "recipient_interceptor"

gem "rails", "~> 6.1.7"
gem "image_processing"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", ">= 1.1.0", require: false

gem "pg", ">= 0.18", "< 2.0"
gem "puma", "~> 5.6"
gem "rack-cors"
gem "rack-timeout", groups: [:production]

gem "delayed_job_active_record"

gem "aws-sdk-s3", "~> 1"
gem "aws-sdk-rails", "~> 3"

# Wonde API client
gem "wondeclient", "~> 0.1.3"

# Templates
gem "slim"
gem "jbuilder", "~> 2.5"
gem "high_voltage"

# Assets
gem "shakapacker", "= 7.2.3"

# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem "turbolinks", "~> 5.2.0"
gem "turbolinks_render" # Aids in rendering form validation errors using ajax

# User authentication
gem "devise"
gem "devise_invitable"
gem "omniauth"
gem "omniauth-oauth2"
gem "omniauth-wonde", path: "omniauth-wonde/"
gem "omniauth-google-oauth2"
gem "omniauth-rails_csrf_protection"

# User authorization
gem "pundit"
gem "rolify"

# React-rails for react components
gem "react-rails", "~> 2.7"

# Form builder
gem "simple_form"

# Bootstrap for emails
gem "bootstrap-email"
gem "sass-embedded", "~> 1.53.0"

# Dyno scaling
gem "hirefire-resource"

# Metrics
gem "scout_apm"
gem "barnes"

group :development, :test do
  gem "rspec-rails"

  gem "ffaker"
  gem "factory_bot_rails"

  # Stub and expect HTTP requests
  gem "webmock"

  # Create a fake API
  gem "vcr"

  # Linting
  gem "standard"
end

group :development do
  gem "listen", "~> 3.3"
  gem "stringio"

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem "spring"
  gem "spring-watcher-listen", "~> 2.0.0"

  # Debugging
  gem "better_errors"
  gem "binding_of_caller"
  gem "web-console", ">= 3.3.0"

  # Pry for debugging goodness
  gem "pry-rails"

  # Log messages sent to/from server
  gem "httplog"

  # Hunt for n+1
  gem "bullet"
end

group :test do
  gem "capybara"
  gem "rspec-retry"
  gem "selenium-webdriver"
  gem "shoulda-matchers", "~> 5.3"
  gem "webdrivers"

  gem "simplecov", require: false
  gem "rspec_junit_formatter"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]
