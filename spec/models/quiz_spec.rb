# frozen_string_literal: true

require "rails_helper"

RSpec.describe Quiz, :default_creates do
  it "has a valid factory" do
    expect(build(:quiz)).to be_valid
  end

  context "when a quiz is created" do
    let!(:quiz) { create(:quiz, user: student, topic: topic) }
    let(:usage_statistic) { UsageStatistic.find_by!(user: student, date: Date.current) }

    it "creates a usage statistic for today" do
      expect(usage_statistic.quizzes_started).to eq(1)
    end

    context "with an existing statistic from a previous day" do
      let!(:old_statistic) { create(:usage_statistic, user: student, date: 1.day.ago) }

      it "does not update the previous day's statistic" do
        expect(usage_statistic.quizzes_started).to eq(1)
      end

      it "creates a new statistic record" do
        expect(usage_statistic.id).not_to eq(old_statistic.id)
      end
    end
  end
end
