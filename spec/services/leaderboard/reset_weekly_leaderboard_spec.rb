# frozen_string_literal: true

require 'rails_helper'
require 'support/session_helpers'

RSpec.describe Leaderboard::ResetWeeklyLeaderboard, :default_creates do
  let(:topic_score) { create(:topic_score) }
  let(:top_score_same_school) do
    create(:topic_score, topic: topic_score.topic,
                         school: topic_score.school,
                         score: 100_000_00)
  end
  let(:existing_all_time_score) { create(:all_time_topic_score, user: topic_score.user, topic: topic_score.topic) }

  context 'when resetting topic scores' do
    it 'copies the current topic score into the all time topic score' do
      topic_score
      described_class.new.call
      expect(AllTimeTopicScore.first.score).to eq(topic_score.score)
    end

    it 'adds on to any existing all time topic score' do
      existing_all_time_score
      expect { described_class.new.call }.to change { AllTimeTopicScore.first.score }.by(topic_score.score)
    end

    it 'removes existing TopicScores' do
      topic_score
      expect { described_class.new.call }.to change(TopicScore, :count).by(-1)
    end
  end

  context 'when adding weekly rewards' do
    it 'awards it to the top scorer for a subject' do
      topic_score
      create_list(:topic_score, 20, topic: topic_score.topic, school: topic_score.school)
      top_score_same_school
      described_class.new.call
      expect(LeaderboardAward.first.user).to eq(top_score_same_school.user)
    end

    it 'adds two awards for two different schools' do
      create_list(:topic_score, 2)
      expect { described_class.new.call }.to change(LeaderboardAward, :count).by(2)
    end

    it 'adds one award for two users of the same school' do
      topic_score
      top_score_same_school
      expect { described_class.new.call }.to change(LeaderboardAward, :count).by(1)
    end

    it 'does not add an award if there are no scores' do
      create(:student)
      expect { described_class.new.call }.not_to change(LeaderboardAward, :count)
    end

    it 'gives awards for three people with the same score' do
      create_list(:topic_score, 3, school: school, score: 100)
      expect { described_class.new.call }.to change(LeaderboardAward, :count).by(3)
    end
  end

  context 'when awarding classroom winners' do
    let(:student_enrollment) { create(:enrollment, classroom: classroom, user: student) }
    let(:previous_winner) { create(:classroom_winner, classroom: classroom, user: student) }
    let(:top_score) { create(:topic_score, subject: classroom.subject, user: student, score: 1000) }
    let(:enrollments) { create_list(:enrollment, 5, classroom: classroom) }
    let(:topic) { create(:topic, subject: classroom.subject) }
    let(:second_classroom) { create(:classroom, school: school, subject: subject) }
    let(:second_classroom_enrollment) { create(:enrollment, classroom: second_classroom) }

    before do
      enrollments.each { |e| create(:topic_score, user: e.user, topic: topic, score: 100) }
      student_enrollment
      top_score
    end

    it 'removes previous winners' do
      previous_winner
      expect { described_class.new.call }.not_to change(ClassroomWinner, :count)
    end

    it 'awards the classroom winner to the top scorer' do
      described_class.new.call
      expect(ClassroomWinner.first.user).to eq(top_score.user)
    end

    it 'records the score of the winner' do
      create_list(:topic_score, 3, school: school, subject: classroom.subject, score: 100)
      described_class.new.call
      expect(ClassroomWinner.first.score).to eq(1000)
    end

    it 'can handle multiple classrooms' do
      second_classroom_enrollment
      create(:topic_score, user: second_classroom_enrollment.user, subject: subject)
      expect { described_class.new.call }.to change(ClassroomWinner, :count).by(2)
    end
  end
end
