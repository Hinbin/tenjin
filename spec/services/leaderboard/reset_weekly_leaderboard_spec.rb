# frozen_string_literal: true

require "rails_helper"

RSpec.describe Leaderboard::ResetWeeklyLeaderboard, :default_creates do
  context "when resetting topic scores" do
    let!(:topic_score) { create(:topic_score) }

    it "copies the current topic score into the all time topic score" do
      described_class.call
      expect(AllTimeTopicScore.find_by!(user: topic_score.user, topic: topic_score.topic).score)
        .to eq(topic_score.score)
    end

    it "removes existing topic scores" do
      expect { described_class.call }.to change(TopicScore, :count).by(-1)
    end

    context "with an existing all time topic score" do
      let!(:existing) { create(:all_time_topic_score, user: topic_score.user, topic: topic_score.topic) }

      it "adds the current score on top" do
        expect { described_class.call }.to change { existing.reload.score }.by(topic_score.score)
      end
    end
  end

  context "when adding weekly rewards" do
    context "with a clear top scorer in a single school" do
      let!(:baseline_score) { create(:topic_score) }
      let!(:other_scorers) { create_list(:topic_score, 20, topic: baseline_score.topic, school: baseline_score.school) }
      let!(:top_scorer) do
        create(:topic_score, topic: baseline_score.topic, school: baseline_score.school, score: 10_000_000)
      end

      it "awards the top scorer" do
        described_class.call
        expect(LeaderboardAward.find_by!(user: top_scorer.user)).to be_present
      end
    end

    context "with scorers in two different schools" do
      before { create_list(:topic_score, 2) }

      it "adds one award per school" do
        expect { described_class.call }.to change(LeaderboardAward, :count).by(2)
      end
    end

    context "with two scorers in the same school" do
      let!(:baseline_score) { create(:topic_score) }
      let!(:top_scorer) do
        create(:topic_score, topic: baseline_score.topic, school: baseline_score.school, score: 10_000_000)
      end

      it "adds a single award" do
        expect { described_class.call }.to change(LeaderboardAward, :count).by(1)
      end
    end

    context "with no scores" do
      before { create(:student) }

      it "does not add an award" do
        expect { described_class.call }.not_to change(LeaderboardAward, :count)
      end
    end

    context "with a tied top score" do
      before { create_list(:topic_score, 3, school: school, score: 100) }

      it "awards every user who shares it" do
        expect { described_class.call }.to change(LeaderboardAward, :count).by(3)
      end
    end
  end

  context "when checking query efficiency" do
    let(:local_school) { create(:school) }
    let(:maths_subject) { create(:subject, name: "Maths") }

    before { create_list(:classroom, 3, school: local_school, subject: maths_subject) }

    it "builds each (school, subject) leaderboard only once" do
      call_count = 0
      allow(Leaderboard::Query).to receive(:new).and_wrap_original do |original, *args|
        call_count += 1
        original.call(*args)
      end

      described_class.call

      # Before fix: 3 (classrooms) + 1 (awards) = 4 calls. After fix: 1 per school×subject pair.
      expect(call_count).to be <= Subject.count * School.count
    end
  end

  context "when awarding classroom winners" do
    let(:topic) { create(:topic, subject: classroom.subject) }
    let!(:student_enrollment) { create(:enrollment, classroom: classroom, user: student) }
    let!(:other_enrollments) { create_list(:enrollment, 5, classroom: classroom) }
    let!(:top_score) { create(:topic_score, subject: classroom.subject, user: student, score: 1000) }

    before do
      other_enrollments.each { |e| create(:topic_score, user: e.user, topic: topic, score: 100) }
    end

    it "awards the classroom winner to the top scorer" do
      described_class.call
      expect(ClassroomWinner.find_by!(classroom: classroom).user).to eq(top_score.user)
    end

    context "when a previous winner already exists" do
      let!(:previous_winner) { create(:classroom_winner, classroom: classroom, user: student) }

      it "replaces previous winners rather than accumulating them" do
        expect { described_class.call }.not_to change(ClassroomWinner, :count)
      end
    end

    context "with additional school-wide topic scores" do
      before { create_list(:topic_score, 3, school: school, subject: classroom.subject, score: 100) }

      it "records the winner's score" do
        described_class.call
        expect(ClassroomWinner.find_by!(classroom: classroom).score).to eq(1000)
      end
    end

    context "with a second classroom in the school" do
      let!(:second_classroom) { create(:classroom, school: school, subject: quiz_subject) }
      let!(:second_classroom_enrollment) { create(:enrollment, classroom: second_classroom) }
      let!(:second_classroom_score) do
        create(:topic_score, user: second_classroom_enrollment.user, subject: quiz_subject)
      end

      it "awards winners for each classroom" do
        expect { described_class.call }.to change(ClassroomWinner, :count).by(2)
      end
    end
  end
end
