# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::ResetYear do
  let!(:first_enrollment) { create(:enrollment) }
  let!(:second_enrollment) { create(:enrollment) }
  let!(:homework) { create(:homework, classroom: first_enrollment.classroom) }
  let!(:topic_score) { create(:topic_score, subject: first_enrollment.classroom.subject) }
  let!(:all_time_topic_score) { create(:all_time_topic_score, subject: second_enrollment.classroom.subject) }
  let!(:homework_progress) { create(:homework_progress, homework: homework, user: first_enrollment.user) }
  let!(:challenge_progress) { create(:challenge_progress, user: first_enrollment.user) }
  let!(:leaderboard_award) do
    create(:leaderboard_award, user: first_enrollment.user, subject: first_enrollment.classroom.subject)
  end
  let!(:classroom_winner) do
    create(:classroom_winner, user: first_enrollment.user, classroom: first_enrollment.classroom)
  end

  before { described_class.call }

  it "purges all year-bound data", :aggregate_failures do
    expect(TopicScore.count).to be_zero
    expect(AllTimeTopicScore.count).to be_zero
    expect(Homework.count).to be_zero
    expect(HomeworkProgress.count).to be_zero
    expect(Enrollment.count).to be_zero
    expect(Challenge.count).to be_zero
    expect(ChallengeProgress.count).to be_zero
    expect(LeaderboardAward.count).to be_zero
    expect(Classroom.count).to be_zero
    expect(ClassroomWinner.count).to be_zero
  end
end
