# frozen_string_literal: true

require "rails_helper"

RSpec.describe School::Statistics, :default_creates do
  describe "with a school scope" do
    subject(:stats) { described_class.new(school) }

    describe "#asked_questions" do
      it "sums questions answered by the school's users" do
        create(:user_statistic, user: create(:student, school: school), questions_answered: 5)
        create(:user_statistic, user: create(:student, school: create(:school)), questions_answered: 99)
        expect(stats.asked_questions).to eq 5
      end

      it "memoizes the result across calls" do
        create(:user_statistic, user: create(:student, school: school), questions_answered: 5)
        stats.asked_questions
        expect(UserStatistic).not_to receive(:sum)
        stats.asked_questions
      end
    end

    describe "#asked_questions_weekly" do
      it "sums only this week's questions for the school" do
        create(:user_statistic,
          user: create(:student, school: school),
          questions_answered: 3,
          week_beginning: Date.current.beginning_of_week)
        create(:user_statistic,
          user: create(:student, school: school),
          questions_answered: 10,
          week_beginning: 2.weeks.ago.beginning_of_week)
        expect(stats.asked_questions_weekly).to eq 3
      end
    end

    describe "#homeworks_completed" do
      it "counts completed homeworks for the school's users" do
        user = create(:student, school: school)
        other_user = create(:student, school: create(:school))
        create(:homework_progress, user: user, completed: true)
        create(:homework_progress, user: other_user, completed: true)
        expect(stats.homeworks_completed).to eq 1
      end

      it "excludes incomplete homeworks" do
        user = create(:student, school: school)
        create(:homework_progress, user: user, completed: false)
        expect(stats.homeworks_completed).to eq 0
      end
    end

    describe "#homeworks_completed_weekly" do
      it "counts completed homeworks updated this week for the school" do
        user = create(:student, school: school)
        create(:homework_progress, user: user, completed: true, updated_at: Time.current)
        create(:homework_progress, user: user, completed: true, updated_at: 2.weeks.ago)
        expect(stats.homeworks_completed_weekly).to eq 1
      end
    end

    describe "#customisation_unlocks" do
      it "counts customisation unlocks for the school's users" do
        user = create(:student, school: school)
        other_user = create(:student, school: create(:school))
        create(:customisation_unlock, user: user)
        create(:customisation_unlock, user: other_user)
        expect(stats.customisation_unlocks).to eq 1
      end
    end

    describe "#customisation_unlocks_weekly" do
      it "counts customisation unlocks updated this week for the school" do
        user = create(:student, school: school)
        create(:customisation_unlock, user: user, updated_at: Time.current)
        create(:customisation_unlock, user: user, updated_at: 2.weeks.ago)
        expect(stats.customisation_unlocks_weekly).to eq 1
      end
    end
  end

  describe "without a school scope" do
    subject(:stats) { described_class.new }

    it "sums questions across all schools" do
      create(:user_statistic, questions_answered: 10)
      create(:user_statistic, questions_answered: 7)
      expect(stats.asked_questions).to eq 17
    end

    it "counts homeworks across all schools" do
      create(:homework_progress, completed: true)
      create(:homework_progress, completed: true)
      expect(stats.homeworks_completed).to eq 2
    end

    it "counts customisation unlocks across all schools" do
      create(:customisation_unlock)
      create(:customisation_unlock)
      expect(stats.customisation_unlocks).to eq 2
    end
  end
end
