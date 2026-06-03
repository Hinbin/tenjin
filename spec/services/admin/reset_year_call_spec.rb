# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::ResetYear, '#call', :default_creates do
  before do
    create_active_database
  end

  let(:first_enrollment) { create(:enrollment) }
  let(:second_enrollment) { create(:enrollment) }
  let(:homework) { create(:homework, classroom: first_enrollment.classroom) }
  let(:topic_score) { create(:topic_score, subject: first_enrollment.classroom.subject) }
  let(:all_time_topic_score) { create(:all_time_topic_score, subject: second_enrollment.classroom.subject) }
  let(:homework_progress) { create(:homework_progress, homework: homework, user: first_enrollment.user) }
  let(:challenge_progress) { create(:challenge_progress, user: first_enrollment.user) }
  let(:leaderboard_award) do
    create(:leaderboard_award, user: first_enrollment.user, subject: first_enrollment.classroom.subject)
  end
  let(:classroom_winner) do
    create(:classroom_winner, user: first_enrollment.user, classroom: first_enrollment.classroom)
  end

  def create_active_database
    first_enrollment
    second_enrollment
    topic_score
    all_time_topic_score
    homework_progress
    challenge_progress
    classroom_winner
    leaderboard_award
  end

  it 'removes topic scores' do
    described_class.call
    expect(TopicScore.count).to eq(0)
  end

  it 'removes all time topic scores' do
    described_class.call
    expect(AllTimeTopicScore.count).to eq(0)
  end

  it 'removes homeworks' do
    described_class.call
    expect(Homework.count).to eq(0)
  end

  it 'removes homework progress' do
    described_class.call
    expect(HomeworkProgress.count).to eq(0)
  end

  it 'removes enrollments' do
    described_class.call
    expect(Enrollment.count).to eq(0)
  end

  it 'removes challenges' do
    described_class.call
    expect(Challenge.count).to eq(0)
  end

  it 'removes challenge progress' do
    described_class.call
    expect(ChallengeProgress.count).to eq(0)
  end

  it 'removes leaderboard awards' do
    described_class.call
    expect(LeaderboardAward.count).to eq(0)
  end

  it 'removes classrooms' do
    described_class.call
    expect(Classroom.count).to eq(0)
  end

  it 'removes classroom winners' do
    described_class.call
    expect(ClassroomWinner.count).to eq(0)
  end
end
