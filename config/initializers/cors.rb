# frozen_string_literal: true

# Configure Rack::Cors middleware
#
# Add CORS headers when serving assets
# Whitelist permitted frontend origins
if defined? Rack::Cors
  Rails.configuration.middleware.insert_before 0, Rack::Cors do
    allow do
      origins(ENV.fetch('CORS_ORIGINS', '').split(',').map(&:strip))

      resource '/assets/*', headers: :any, methods: %i[get head options]
      resource '/packs/*', headers: :any, methods: %i[get head options]
    end
  end
end
