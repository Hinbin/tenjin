# frozen_string_literal: true

ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup" # Set up gems listed in the Gemfile.
require "logger" # Remove when using Rails 7.1
require "bootsnap/setup" # Speed up boot time by caching expensive operations.
