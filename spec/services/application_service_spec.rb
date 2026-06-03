# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationService::Result do
  subject(:result) { described_class.new(success: true, value: 42) }

  it 'exposes attributes with hash-style access' do
    expect(result[:value]).to eq(42)
  end

  it 'accepts string keys for hash-style access' do
    expect(result['value']).to eq(42)
  end
end
