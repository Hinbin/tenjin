# frozen_string_literal: true

# This file is copied to spec/ when you run 'rails generate rspec:install'
require "spec_helper"
ENV["RAILS_ENV"] ||= "test"
require File.expand_path("../config/environment", __dir__)
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require "rspec/rails"
# Add additional requires below this line. Rails is not loaded until this point!

require "capybara/rails"
require "webmock/rspec"
require "vcr"
require "super_diff/rspec-rails"

WebMock.disable_net_connect!(allow_localhost: true)

# Prevent ActionCable WebSocket upgrades to /cable from interfering
# with Devise session state.
Warden::Manager.prepend(Module.new do
  def call(env)
    return @app.call(env) if %r{^/cable}.match?(env["PATH_INFO"])
    super
  end
end)

VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock
  config.ignore_localhost = true # allows oAuth testing
  config.configure_rspec_metadata!
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
Dir[Rails.root.join("spec/support/**/*.rb")].sort.each { |f| require f }

# Checks for pending migrations and applies them before tests are run.
# If you are not using ActiveRecord, you can remove these lines.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  puts e.to_s.strip
  exit 1
end

CUPRITE_OPTIONS = {
  window_size: [1024, 768],
  process_timeout: 30,
  timeout: 15,
  js_errors: true,
  browser_options: {"headless" => "new"}
}.freeze

Capybara.register_driver :cuprite do |app|
  Capybara::Cuprite::Driver.new(app, **CUPRITE_OPTIONS)
end

RSpec.configure do |config|
  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

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
  config.include Devise::Test::IntegrationHelpers, type: :system
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include SessionHelpers, type: :system
  config.include ActiveJob::TestHelper, type: :job

  config.include_context "with default_creates", default_creates: true

  # Required to use database cleaner with action cable
  # or feature testing will not work

  config.before(:each, type: :system) do
    driven_by :cuprite
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

Capybara.server = :puma, {Silent: true}
Capybara.default_max_wait_time = ENV["CI"] ? 15 : 5
