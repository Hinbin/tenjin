# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Super views all statistics", :default_creates, :js do
  before do
    sign_in super_admin
  end

  let(:two_weeks_ago) { (Date.current - 2.weeks).beginning_of_week }

  describe "viewing asked questions" do
    let!(:new_stat) { create(:user_statistic, user: student, week_beginning: Date.current.beginning_of_week) }
    let!(:old_stat) { create(:user_statistic, user: create(:student, school: school), week_beginning: two_weeks_ago) }
    let!(:new_stat_different_school) { create(:user_statistic, week_beginning: Date.current.beginning_of_week) }
    let!(:old_stat_different_school) do
      create(:user_statistic, user: create(:student, school: school), week_beginning: two_weeks_ago)
    end
    let(:total_answered) do
      [new_stat.questions_answered,
        old_stat.questions_answered,
        new_stat_different_school.questions_answered,
        old_stat_different_school.questions_answered].sum
    end
    let(:weekly_answered) { new_stat.questions_answered + new_stat_different_school.questions_answered }

    before { visit(show_stats_schools_path) }

    it "shows total questions answered" do
      expect(page).to have_css("#asked_questions", exact_text: total_answered.to_s)
    end

    it "shows this week's questions answered" do
      expect(page).to have_css("#asked_questions_weekly", exact_text: weekly_answered.to_s)
    end
  end

  describe "viewing completed homework" do
    let!(:homework_progress) do
      create(:homework_progress, user: student,
        completed: true, updated_at: Date.current.beginning_of_week)
    end
    let!(:old_homework_progress) do
      create(:homework_progress, user: student,
        completed: true, updated_at: two_weeks_ago)
    end
    let!(:homework_progress_different_school) do
      create(:homework_progress,
        completed: true, updated_at: Date.current.beginning_of_week)
    end
    let!(:old_homework_progress_different_school) do
      create(:homework_progress,
        completed: true, updated_at: two_weeks_ago)
    end

    before { visit(show_stats_schools_path) }

    it "shows total homeworks completed" do
      expect(page).to have_css("#homeworks_completed", exact_text: "4")
    end

    it "shows this week's completed homeworks" do
      expect(page).to have_css("#homeworks_completed_weekly", exact_text: "2")
    end
  end
end
