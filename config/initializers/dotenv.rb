if ENV['RAILS_ENV'] = "development" || "test"
  Dotenv.require_keys("WONDE_SECRET", "WONDE_CLIENT_ID", "WONDE_CALLBACK_URL", # Wonde ENV vars
                      "AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY"             # AWS for ActiveStorage ENV
                    )
end