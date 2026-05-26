# frozen_string_literal: true

require "rails_helper"

RSpec.describe Customisation do
  it "has a valid factory" do
    expect(build(:customisation)).to be_valid
  end

  describe "validation" do
    subject { build(:customisation, customisation_type: type) }

    let(:type) { "leaderboard_icon" }

    it { is_expected.to validate_presence_of(:cost) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:value) }

    context "with a dashboard_style" do
      let(:type) { "dashboard_style" }

      it { is_expected.to validate_presence_of(:image) }
    end

    context "with a leaderboard_icon" do
      let(:type) { "leaderboard_icon" }

      it { is_expected.not_to validate_presence_of(:image) }
    end

    context "with a subject_image" do
      let(:type) { "subject_image" }

      it { is_expected.not_to validate_presence_of(:image) }
    end
  end

  context "when retired" do
    let!(:customisation) { create(:customisation, retired: true, purchasable: true, customisation_type: "leaderboard_icon") }

    it "is not purchasable" do
      expect(customisation.reload).not_to be_purchasable
    end
  end

  context "when not retired" do
    it "is purchasable" # pending — counterpart to "when retired" context
  end
end
