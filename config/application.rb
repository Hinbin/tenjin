# frozen_string_literal: true

require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Csquiz
  class Application < Rails::Application
    config.load_defaults 7.0

    config.active_storage.variant_processor = :mini_magick
    config.active_support.disable_to_s_conversion = true
    config.active_support.cache_format_version = 7.0

    config.action_mailer.delivery_method = :ses
    config.action_mailer.asset_host = ENV["ASSET_HOST"]
  end
end
