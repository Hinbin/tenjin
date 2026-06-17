require_relative "boot"
require_relative "../app/middleware/app_error_middleware"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Csquiz
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
    config.middleware.use AppErrorMiddleware

    # Also compile the mailer stylesheet (bootstrap-email inlines it into emails)
    config.dartsass.builds = {
      "application.scss"        => "application.css",
      "application-mailer.scss" => "application-mailer.css"
    }
    # Add bootstrap-email gem's SCSS core to asset paths so dartsass can
    # resolve @import 'bootstrap-email' in application-mailer.scss.
    config.assets.paths << Gem::Specification.find_by_name("bootstrap-email").gem_dir + "/core"
  end
end
