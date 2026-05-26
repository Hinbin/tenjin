# frozen_string_literal: true

require "rails_helper"

RSpec.describe Leaderboard::BuildLeaderboard, :default_creates do
  let(:student) { create(:student, forename: "Aaaron", school: school) } # Ensure first alphabetically
  let(:school) { create(:school, school_group: nil) }

  before do
    create(:enrollment, classroom: classroom, user: student)
    create(:topic_score, topic: topic, user: student)
  end

  context "when returning student data" do
    let(:leaderboard) { described_class.call(student, id: quiz_subject.name).first }
    let(:leaderboard_icon) { create(:customisation, customisation_type: "leaderboard_icon") }
    let(:second_student) { create(:student, school: school) }

    it "includes the school name" do
      expect(leaderboard.school_name).to eq(school.name)
    end

    it "includes the first name and last initial of the student" do
      expect(leaderboard.name).to eq("#{student.forename} #{student.surname.first}")
    end

    context "when the student has an active leaderboard icon" do
      before { create(:active_customisation, user: student, customisation: leaderboard_icon) }

      it "includes the leaderboard icon" do
        expect(leaderboard.icon).to eq(leaderboard_icon.value)
      end
    end

    context "when another student has an active leaderboard icon" do
      before do
        create(:active_customisation, user: second_student, customisation: leaderboard_icon)
        create(:topic_score, topic: topic, user: second_student)
      end

      it "includes the leaderboard icon for that student" do
        expect(described_class.call(student, id: quiz_subject.name)
          .find { |user| user["id"] == second_student.id }.icon).to eq(leaderboard_icon.value)
      end
    end

    context "when another student has no active icon" do
      before { create(:topic_score, topic: topic, user: second_student) }

      it "returns a nil icon for that student" do
        expect(described_class.call(student, id: quiz_subject.name)
          .find { |user| user["id"] == second_student.id }.icon).to be_nil
      end
    end
  end

  context "when building a subject leaderboard" do
    let(:leaderboard) { described_class.call(student, id: quiz_subject.name) }
    let(:topic_different_subject) { create(:topic) }
    let(:topic_same_subject) { create(:topic, subject: quiz_subject) }

    context "with a student who scored in the subject" do
      before { create(:topic_score, topic: topic, school: school, score: 10) }

      it "includes students who have scored in the subject" do
        expect(leaderboard.count).to eq(2)
      end
    end

    context "with a student who scored in a different subject" do
      before { create(:topic_score, topic: topic_different_subject, school: school, score: 10) }

      it "excludes students from other subjects" do
        expect(leaderboard.count).to eq(1)
      end
    end

    context "with scores across multiple topics in the subject" do
      let!(:extra_score) { create(:topic_score, user: student, topic: topic_same_subject, school: school) }

      it "sums scores across all topics in the subject" do
        expect(leaderboard.first.score).to eq(TopicScore.all.sum(:score))
      end
    end
  end

  context "when building a topic leaderboard" do
    let(:leaderboard) { described_class.call(student, id: quiz_subject.name, topic: topic.id) }
    let(:topic_same_subject) { create(:topic, subject: quiz_subject) }

    context "with a student who scored in the topic" do
      before { create(:topic_score, topic: topic, school: school, score: 10) }

      it "includes students who have scored in the topic" do
        expect(leaderboard.count).to eq(2)
      end
    end

    context "with a student who scored in a different topic" do
      before { create(:topic_score, topic: topic_same_subject, school: school) }

      it "excludes students who scored in a different topic" do
        expect(leaderboard.count).to eq(1)
      end

      it "shows only the score for the selected topic" do
        expect(leaderboard.first.score).to eq(TopicScore.find_by!(user: student).score)
      end
    end
  end

  context "when building a leaderboard for a single school" do
    let(:leaderboard) { described_class.call(student, id: quiz_subject.name, topic: topic.id) }
    let(:different_school) { create(:school) }

    context "with a student from the same school" do
      before { create(:topic_score, topic: topic, school: school) }

      it "includes students from the same school" do
        expect(leaderboard.count).to eq(2)
      end
    end

    context "with a student from a different school" do
      before { create(:topic_score, topic: topic, school: different_school) }

      it "excludes students from a different school" do
        expect(leaderboard.count).to eq(1)
      end
    end
  end

  context "when building a school group leaderboard" do
    let(:school) { create(:school) }
    let(:school_different_school_group) { create(:school) }
    let(:student_no_school_group) { create(:student, school: school_without_school_group) }
    let(:leaderboard) { described_class.call(student, id: quiz_subject.name, school_group: "true") }

    context "with a student from a different school group" do
      before { create(:topic_score, topic: topic, school: school_different_school_group) }

      it "excludes students from a different school group" do
        expect(leaderboard.count).to eq(1)
      end
    end

    context "with a student from the same school group" do
      before { create(:topic_score, topic: topic, school: second_school) }

      it "includes students from the same school group" do
        expect(leaderboard.count).to eq(2)
      end
    end

    context "with a student who has no school group" do
      before { create(:topic_score, topic: topic, user: student_no_school_group) }

      it "excludes students with no school group" do
        expect(leaderboard.count).to eq(1)
      end
    end
  end

  context "when building an all time leaderboard" do
    let(:leaderboard) { described_class.call(student, id: quiz_subject.name, all_time: "true") }

    context "with an all time topic score" do
      let!(:all_time_score) { create(:all_time_topic_score, user: student, topic: topic) }

      it "uses all time topic scores instead of weekly scores" do
        expect(leaderboard.first.score).to eq(AllTimeTopicScore.all.sum(:score))
      end
    end
  end
end
