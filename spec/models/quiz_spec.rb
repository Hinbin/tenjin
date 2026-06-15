# frozen_string_literal: true

require "rails_helper"

RSpec.describe Quiz, :default_creates do
  it "has a valid factory" do
    expect(build(:quiz)).to be_valid
  end

  describe ".current_for" do
    let(:user) { create(:student) }

    it "returns nil when the user has no quizzes" do
      expect(Quiz.current_for(user)).to be_nil
    end

    it "returns the only quiz when the user has exactly one" do
      quiz = create(:quiz, user: user)
      expect(Quiz.current_for(user)).to eq quiz
    end

    it "returns the most recent active quiz when several exist" do
      create(:quiz, user: user, created_at: 2.days.ago, active: false)
      recent_active = create(:quiz, user: user, created_at: 1.minute.ago, active: true)
      expect(Quiz.current_for(user)).to eq recent_active
    end

    it "returns nil when the user's only quiz is already inactive" do
      create(:quiz, user: user, active: false)
      expect(Quiz.current_for(user)).to be_nil
    end

    it "ignores inactive quizzes when picking from multiple" do
      create(:quiz, user: user, active: false, created_at: 1.day.ago)
      active = create(:quiz, user: user, active: true, created_at: 1.minute.ago)
      expect(Quiz.current_for(user)).to eq active
    end
  end

  describe ".deactivate_stale_for" do
    let(:user) { create(:student) }

    it "deletes older quizzes that were never answered" do
      empty_old = create(:quiz, user: user, created_at: 2.days.ago, num_questions_asked: 0)
      create(:quiz, user: user, created_at: 1.minute.ago)
      expect { Quiz.deactivate_stale_for(user) }.to change { Quiz.exists?(empty_old.id) }.to(false)
    end

    it "deactivates older quizzes that had progress" do
      progressed_old = create(:quiz, user: user, created_at: 2.days.ago, num_questions_asked: 3, active: true)
      create(:quiz, user: user, created_at: 1.minute.ago)
      Quiz.deactivate_stale_for(user)
      expect(progressed_old.reload.active).to be false
    end
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
