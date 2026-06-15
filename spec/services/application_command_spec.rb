# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationCommand do
  let(:command_class) do
    Class.new(described_class) do
      def initialize(should_succeed:, payload: nil, error: nil)
        @should_succeed = should_succeed
        @payload = payload
        @error = error
      end

      def call
        @should_succeed ? success(@payload) : failure(@error || :unknown_error)
      end
    end
  end

  describe ".call" do
    it "instantiates and invokes call" do
      result = command_class.call(should_succeed: true, payload: 42)
      expect(result).to be_success
      expect(result.payload).to eq 42
    end
  end

  describe "#call default" do
    it "raises NotImplementedError if not overridden" do
      base = Class.new(described_class).new
      expect { base.call }.to raise_error(NotImplementedError, /must define `#call`/)
    end
  end

  describe ApplicationCommand::Result do
    it "treats success as truthy" do
      result = described_class.new(success: true, payload: :ok, error: nil)
      expect(result).to be_success
      expect(result).not_to be_failure
    end

    it "treats failure as falsy" do
      result = described_class.new(success: false, payload: nil, error: :nope)
      expect(result).not_to be_success
      expect(result).to be_failure
    end

    it "is pattern matchable on success" do
      result = described_class.new(success: true, payload: {id: 7}, error: nil)
      matched = case result
      in {success: true, payload: {id:}} then id
      else :no_match
      end
      expect(matched).to eq 7
    end

    it "is pattern matchable on structured error" do
      result = described_class.new(success: false, payload: nil, error: {code: :rate_limited, cooldown: 30})
      matched = case result
      in {success: false, error: {code: :rate_limited, cooldown:}} then cooldown
      else :no_match
      end
      expect(matched).to eq 30
    end
  end
end
