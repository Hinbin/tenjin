# frozen_string_literal: true

require "rails_helper"

RSpec.describe Leaderboard::ResetWeeklyLeaderboard, :default_creates do
  let(:topic_score) { create(:topic_score) }

  context "when resetting topic scores" do
    it "copies the current topic score into the all time topic score" do
      topic_score
      described_class.call
      expect(AllTimeTopicScore.find_by!(user: topic_score.user, topic: topic_score.topic).score)
        .to eq(topic_score.score)
    end

    it "adds on to any existing all time topic score" do
      existing = create(:all_time_topic_score, user: topic_score.user, topic: topic_score.topic)
      expect { described_class.call }.to change { existing.reload.score }.by(topic_score.score)
    end

    it "removes existing topic scores" do
      topic_score
      expect { described_class.call }.to change(TopicScore, :count).by(-1)
    end
  end

  context "when adding weekly rewards" do
    let(:top_score_same_school) do
      create(:topic_score, topic: topic_score.topic,
        school: topic_score.school,
        score: 10_000_000)
    end

    it "awards the top scorer for a subject" do
      topic_score
      create_list(:topic_score, 20, topic: topic_score.topic, school: topic_score.school)
      top_score_same_school
      described_class.call
      expect(LeaderboardAward.find_by!(user: top_score_same_school.user)).to be_present
    end

    it "adds one award per school" do
      create_list(:topic_score, 2)
      expect { described_class.call }.to change(LeaderboardAward, :count).by(2)
    end

    it "adds one award for multiple users of the same school" do
      topic_score
      top_score_same_school
      expect { described_class.call }.to change(LeaderboardAward, :count).by(1)
    end

    it "does not add an award if there are no scores" do
      create(:student)
      expect { described_class.call }.not_to change(LeaderboardAward, :count)
    end

    it "awards all users who share the top score" do
      create_list(:topic_score, 3, school: school, score: 100)
      expect { described_class.call }.to change(LeaderboardAward, :count).by(3)
    end
  end

  context "when awarding classroom winners" do
    let(:student_enrollment) { create(:enrollment, classroom: classroom, user: student) }
    let(:previous_winner) { create(:classroom_winner, classroom: classroom, user: student) }
    let(:top_score) { create(:topic_score, subject: classroom.subject, user: student, score: 1000) }
    let(:enrollments) { create_list(:enrollment, 5, classroom: classroom) }
    let(:topic) { create(:topic, subject: classroom.subject) }
    let(:second_classroom) { create(:classroom, school: school, subject: quiz_subject) }
    let(:second_classroom_enrollment) { create(:enrollment, classroom: second_classroom) }

    before do
      enrollments.each { |e| create(:topic_score, user: e.user, topic: topic, score: 100) }
      student_enrollment
      top_score
    end

    it "replaces previous winners rather than accumulating them" do
      previous_winner
      expect { described_class.call }.not_to change(ClassroomWinner, :count)
    end

    it "awards the classroom winner to the top scorer" do
      described_class.call
      expect(ClassroomWinner.find_by!(classroom: classroom).user).to eq(top_score.user)
    end

    it "records the winner's score" do
      create_list(:topic_score, 3, school: school, subject: classroom.subject, score: 100)
      described_class.call
      expect(ClassroomWinner.find_by!(classroom: classroom).score).to eq(1000)
    end

    it "awards winners for multiple classrooms" do
      second_classroom_enrollment
      create(:topic_score, user: second_classroom_enrollment.user, subject: quiz_subject)
      expect { described_class.call }.to change(ClassroomWinner, :count).by(2)
    end
  end
end
