# frozen_string_literal: true

require "rails_helper"

RSpec.describe TopicScore do
  it { is_expected.to belong_to(:topic) }
  it { is_expected.to belong_to(:user) }
  it { is_expected.to have_one(:subject).through(:topic) }

  it "has a valid factory" do
    expect(build(:topic_score)).to be_valid
  end

  describe "validations" do
    subject { build(:topic_score) }

    it { is_expected.to validate_numericality_of(:score).is_greater_than_or_equal_to(0) }
  end
end
