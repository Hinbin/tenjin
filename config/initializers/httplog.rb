if Rails.env.development?
  HttpLog.configure do |config|
    config.logger = Rails.logger
    config.color = :red
    config.log_headers = true
  end
end
