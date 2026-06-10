# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Super views all statistics", :default_creates, :js do
  let(:two_weeks_ago) { (Date.current - 2.weeks).beginning_of_week }
  let(:this_week) { Date.current.beginning_of_week }
  let(:other_school) { create(:school) }
  let(:other_school_student) { create(:student, school: other_school) }

  before { sign_in super_admin }

  describe "viewing asked questions" do
    let!(:new_stat) { create(:user_statistic, user: student, week_beginning: this_week) }
    let!(:old_stat) { create(:user_statistic, user: student, week_beginning: two_weeks_ago) }
    let!(:new_stat_other_school) { create(:user_statistic, user: other_school_student, week_beginning: this_week) }
    let!(:old_stat_other_school) { create(:user_statistic, user: other_school_student, week_beginning: two_weeks_ago) }

    let(:total_answered) { UserStatistic.sum(:questions_answered) }
    let(:weekly_answered) { UserStatistic.where(week_beginning: this_week).sum(:questions_answered) }

    before { visit(show_stats_schools_path) }

    it "shows total questions answered" do
      expect(page).to have_css("#asked_questions", exact_text: total_answered.to_s)
    end

    it "shows this week's questions answered" do
      expect(page).to have_css("#asked_questions_weekly", exact_text: weekly_answered.to_s)
    end
  end

  describe "viewing completed homework" do
    before do
      create(:homework_progress, user: student, completed: true, updated_at: this_week)
      create(:homework_progress, user: student, completed: true, updated_at: two_weeks_ago)
      create(:homework_progress, user: other_school_student, completed: true, updated_at: this_week)
      create(:homework_progress, user: other_school_student, completed: true, updated_at: two_weeks_ago)
      visit(show_stats_schools_path)
    end

    it "shows total homeworks completed" do
      expect(page).to have_css("#homeworks_completed", exact_text: HomeworkProgress.where(completed: true).count.to_s)
    end

    it "shows this week's completed homeworks" do
      expect(page).to have_css("#homeworks_completed_weekly",
        exact_text: HomeworkProgress.where(completed: true, updated_at: this_week..).count.to_s)
    end
  end
end
