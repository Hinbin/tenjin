# frozen_string_literal: true

# Service object base class
class ApplicationService
  def self.call(*args, &block)
    new(*args, &block).call
  end

  def call
    raise NotImplementedError
  end
end
