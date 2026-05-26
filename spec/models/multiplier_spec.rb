# frozen_string_literal: true

require "rails_helper"

RSpec.describe Multiplier do
  it { is_expected.to validate_presence_of(:score) }
  it { is_expected.to validate_uniqueness_of(:score) }
  it { is_expected.to validate_presence_of(:multiplier) }

  it "is valid with default attributes" do
    expect(build(:multiplier)).to be_valid
  end
end
