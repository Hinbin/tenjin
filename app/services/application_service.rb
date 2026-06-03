# frozen_string_literal: true

# Service object base class
class ApplicationService
  class Result
    def initialize(**attributes)
      @attributes = attributes
    end

    def success?
      @attributes.fetch(:success, false)
    end

    def completed?
      @attributes.fetch(:completed, false)
    end

    def method_missing(method_name, *args, &block)
      return @attributes[method_name] if args.empty? && block.nil? && @attributes.key?(method_name)

      super
    end

    def respond_to_missing?(method_name, include_private = false)
      @attributes.key?(method_name) || super
    end
  end

  def self.call(*, &)
    new(*, &).call
  end

  def call
    raise NotImplementedError
  end

  private

  def result(**attributes)
    Result.new(**attributes)
  end
end
