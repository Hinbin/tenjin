# frozen_string_literal: true

# Base class for command-style services that may succeed or fail.
#
# Subclasses must implement `#call` and should return either `success(payload)` or
# `failure(error, payload: ...)`. The wrapper enforces that the public `.call`
# entry point always returns a Result.
#
# Queries (read-only data aggregation) belong in app/queries/, not here.
# Side-effect-only services (fire-and-forget) inherit ApplicationService instead.
class ApplicationCommand
  Result = Data.define(:success, :payload, :error) do
    def success? = success
    def failure? = !success
  end

  def self.call(...)
    new(...).call
  end

  def call
    raise NotImplementedError, "#{self.class} must define `#call`"
  end

  private

  def success(payload = nil)
    Result.new(success: true, payload: payload, error: nil)
  end

  def failure(error = :unknown_error, payload: nil)
    Result.new(success: false, payload: payload, error: error)
  end
end
