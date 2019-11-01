# frozen_string_literal: true

# Start code coverage
require 'simplecov'
SimpleCov.start 'rails'

# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../config/environment', __dir__)
# Prevent database truncation if the environment is production
abort('The Rails environment is running in production mode!') if Rails.env.production?
require 'rspec/rails'
# Add additional requires below this line. Rails is not loaded until this point!
require 'webdrivers'

require 'webmock/rspec'
require 'vcr'

require 'action_cable/testing/rspec'
require 'action_cable/testing/rspec/features'

require 'best_in_place'
require 'best_in_place/test_helpers'

WebMock.disable_net_connect!(allow_localhost: true)
# WebMock.allow_net_connect!

VCR.configure do |config|
  config.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  config.hook_into :webmock
  config.ignore_localhost = true # allows oAuth testing
  config.configure_rspec_metadata!
  config.ignore_hosts 'chromedriver.storage.googleapis.com'
end

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
Dir[Rails.root.join('spec', 'support', '**', '*.rb')].each { |f| require f }

# Checks for pending migrations and applies them before tests are run.
# If you are not using ActiveRecord, you can remove these lines.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  puts e.to_s.strip
  exit 1
end
RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")

  config.include FactoryBot::Syntax::Methods
  config.include Devise::Test::IntegrationHelpers, type: :feature
  config.include Devise::Test::IntegrationHelpers, type: :system
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include SessionHelpers, type: :feature
  config.include SessionHelpers, type: :system
  config.include BestInPlace::TestHelpers
  config.include ActiveJob::TestHelper

  config.include_context 'default_creates', default_creates: true

  # Allow wait for ajax command
  config.include WaitForAjax, type: :feature

  # Required to use database cleaner with action cable
  # or feature testing will not work
  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each, js: true) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before do
    DatabaseCleaner.start
  end

  config.append_after do
    DatabaseCleaner.clean
  end

  config.after :each, :js do
    errors = page.driver.browser.manage.logs.get(:browser)
    if errors.present?
      aggregate_failures 'javascript errors' do
        errors.each do |error|
          expect(error.level).not_to eq('SEVERE'), error.message
          next unless error.level == 'WARNING'

          warn 'WARN: javascript warning'
          warn error.message
        end
      end
    end
  end

  if ENV['TRAVIS']
    # show retry status in spec process
    config.verbose_retry = true
    # show exception that triggers a retry if verbose_retry is set to true
    config.display_try_failure_messages = true

    # run retry only on features
    config.around :each, :js do |ex|
      ex.run_with_retry retry: 3
    end

    # callback to be run between retries
    config.retry_callback = proc do |ex|
      # run some additional clean up task - can be filtered by example metadata
      Capybara.reset! if ex.metadata[:js]
      DatabaseCleaner.clean
    end

    config.before(:each, type: :system) do
      driven_by :travis_chrome
    end
  else
    config.before(:each, type: :system) do
      driven_by :selenium_chrome_headless
    end
  end
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    # Choose a test framework:
    with.test_framework :rspec

    # Or, choose all of the above:
    with.library :rails
  end
end

Capybara.server = :puma, { Silent: true }

if ENV['TRAVIS']
  Capybara.register_driver :travis_chrome do |app|
    options = Selenium::WebDriver::Chrome::Options.new(args: %w[no-sandbox headless disable-gpu])

    Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
  end

  Capybara.javascript_driver = :travis_chrome

  # Increase timeouts to avoid intermittent failures
  Capybara.default_max_wait_time = 15

else
  Capybara.default_driver = :selenium_chrome_headless
  Capybara.javascript_driver = :selenium_chrome_headless

end
