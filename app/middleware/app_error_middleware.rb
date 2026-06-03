# frozen_string_literal: true

class AppErrorMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    @app.call(env)
  rescue StandardError => e
    AppErrorReporter.report(e, request: ActionDispatch::Request.new(env))
    raise
  end
end
