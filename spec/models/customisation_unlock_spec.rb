# frozen_string_literal: true

require "rails_helper"

RSpec.describe CustomisationUnlock do
  it "has a valid factory" do
    expect(build(:customisation_unlock)).to be_valid
  end

  describe "validations" do
    it { is_expected.to belong_to(:customisation) }
    it { is_expected.to belong_to(:user) }
  end
end
