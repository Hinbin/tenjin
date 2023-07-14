# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '~> 3.2.2'

# Sets environment variables
gem 'dotenv-rails', groups: [:development, :test]
gem 'recipient_interceptor'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 7.0.5'

gem 'pg', '>= 0.18', '< 2.0'
gem 'puma', '~> 4.3'
gem 'rack-cors', groups: [:production]
gem 'rack-timeout', groups: [:production]

gem 'delayed_job_active_record'

# Templates & asset handling
gem 'jbuilder', '~> 2.5'
gem 'uglifier', '>= 1.3.0'
gem 'jsbundling-rails'

# React-rails for react components
gem 'react-rails'

# Turbo-rails replaces Turbolinks
gem 'turbo-rails'

# Stimulus for Javascript
gem 'stimulus-rails'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4.4', require: false

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'

  # Use the following gems for rspec testing
  gem 'rspec-rails'
  
  # Fast creation of test objects
  gem 'factory_bot_rails'
  # Lets us mock web calls
  gem 'webmock'
  # Allows us to create a fake API
  gem 'vcr'

  # Random strings for testing
  gem 'ffaker'

end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'listen', '>= 3.0.5', '< 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'web-console', '>= 3.3.0'
  
  # better errors for debugging
  gem 'better_errors'
  gem 'binding_of_caller'
  
  #httplog to get all messages sent to/from server
  gem 'httplog'

  # Pry for debugging goodness
  gem 'pry-rails'

  # All them rules for development
  gem "rubocop", ">= 1.25.1", require: false
  gem "rubocop-minitest", require: false
  gem "rubocop-packaging", require: false
  gem "rubocop-performance", require: false
  gem "rubocop-rails", require: false
  gem 'rubocop-rspec'

  # Hunt for n+1
  gem 'bullet'

  gem 'debug'

end

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara'
  gem 'selenium-webdriver'
  # Easy installation and use of chromedriver to run system tests with Chrome
  gem 'webdrivers'
  gem 'shoulda-matchers', '4.0.0.rc1'
  gem 'simplecov', require: false # For code coverage
  gem 'rspec-retry'
  gem 'rspec_junit_formatter'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

# User authentication
gem 'devise'
gem 'devise_invitable'
gem 'omniauth'
gem 'omniauth-oauth2'
gem 'omniauth-wonde', :path=>"omniauth-wonde/"
gem 'omniauth-google-oauth2'
gem "omniauth-rails_csrf_protection"  #Required for omniauth > 2.0

# Simple forms
gem 'simple_form'

# Slim for clean HTML
gem 'slim'

# User specific authorization
gem 'pundit'
gem 'rolify'

# Wonde client to easily access Wonde data
gem 'wondeclient', github: 'wondeltd/ruby-client'

# Bootstrap for emails
gem 'bootstrap-email'

# High-voltage for our static pages (e.g. home)
gem 'high_voltage'

#Required for rails 6.1 (recommeneded 1.2)
gem 'image_processing'

# File storage
gem 'aws-sdk-s3'

# SES email
gem 'aws-sdk-rails'

# Investigate memory leaks
gem 'scout_apm'

# Heroku dyno management & statistics
gem 'hirefire-resource'
gem 'barnes'
#skylight for response metrics?


# New image manipulator gem
gem "ruby-vips"

gem "shakapacker", "~> 7.0"
