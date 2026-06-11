# frozen_string_literal: true

require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Csquiz
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    config.active_storage.variant_processor = :mini_magick
    config.active_support.cache_format_version = 7.1

    config.autoload_lib(ignore: %w[assets tasks gem_ext])

    # Rails 7.1: do not add autoloaded paths into $LOAD_PATH.
    config.add_autoload_paths_to_load_path = false

    config.action_mailer.delivery_method = :ses
    config.action_mailer.asset_host = ENV["ASSET_HOST"]
  end
end
