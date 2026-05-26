# frozen_string_literal: true

require "rails_helper"

RSpec.describe Challenge::UpdateChallengeProgress, :default_creates do
  context "with a number_correct challenge" do
    let!(:challenge) do
      create(:challenge, topic: topic, challenge_type: "number_correct",
        number_required: 10, end_date: 1.hour.from_now)
    end
    let(:progress) { ChallengeProgress.find_by(challenge: challenge, user: student) }
    let(:challenge_different_topic) do
      create(:challenge, topic: create(:topic, subject: quiz_subject),
        challenge_type: "number_correct", number_required: 3,
        end_date: 1.hour.from_now)
    end

    let(:quiz_full_marks) do
      create(:quiz, subject: quiz_subject, topic: topic, num_questions_asked: 10,
        answered_correct: 10, active: false, user: student)
    end
    let(:quiz_7_out_of_10) do
      create(:quiz, subject: quiz_subject, topic: topic, num_questions_asked: 10,
        answered_correct: 7, active: false, user: student)
    end

    it "marks the challenge complete" do
      described_class.call(quiz_full_marks)
      expect(progress.completed).to be true
    end

    it "records the number of correct answers as progress" do
      described_class.call(quiz_7_out_of_10)
      expect(progress.progress).to eq(7)
    end

    it "does not decrease progress when a lower score is submitted" do
      described_class.call(quiz_full_marks)
      described_class.call(quiz_7_out_of_10)
      expect(progress.reload.progress).to eq(10)
    end

    it "awards points when the challenge is completed" do
      described_class.call(quiz_full_marks)
      expect { student.reload }.to change(student, :challenge_points).by(challenge.points)
    end

    it "does not update progress for a quiz on a different topic" do
      expect { described_class.call(quiz_full_marks, "number_correct") }
        .not_to(change { ChallengeProgress.where(challenge: challenge_different_topic).count })
    end

    it "only awards points once" do
      described_class.call(quiz_full_marks)
      described_class.call(quiz_full_marks)
      expect(progress.reload.progress).to eq(10)
    end
  end

  context "with a streak challenge" do
    let!(:challenge) do
      create(:challenge, topic: topic, challenge_type: "streak", number_required: 5, end_date: 1.hour.from_now)
    end
    let(:progress) { ChallengeProgress.find_by(challenge: challenge, user: student) }

    let(:quiz_streak_of_five) { create(:quiz, subject: quiz_subject, user: student, topic: topic, streak: 5) }
    let(:quiz_streak_of_three) { create(:quiz, subject: quiz_subject, user: student, topic: topic, streak: 3) }

    it "marks the challenge complete when the streak target is reached" do
      described_class.call(quiz_streak_of_five)
      expect(progress.completed).to be true
    end

    it "records the highest streak as progress" do
      described_class.call(quiz_streak_of_three)
      expect(progress.progress).to eq(3)
    end

    it "awards points when the challenge is completed" do
      described_class.call(quiz_streak_of_five)
      expect { student.reload }.to change(student, :challenge_points).by(challenge.points)
    end

    context "with an already-completed progress record" do
      let!(:completed_progress) do
        create(:challenge_progress, challenge: challenge, user: student, completed: true, awarded: true)
      end

      it "does not award points a second time" do
        described_class.call(quiz_streak_of_five)
        expect { student.reload }.not_to change(student, :challenge_points)
      end

      it "does not reset completed to false after a lower streak" do
        described_class.call(quiz_streak_of_three)
        expect(completed_progress.reload.completed).to be true
      end
    end
  end

  context "with a number_of_points challenge" do
    let(:quiz_five_points) { create(:quiz, subject: quiz_subject, topic: topic, user: student) }
    let(:quiz_five_points_lucky_dip) { create(:quiz, subject: quiz_subject, topic: nil, user: student) }
    let(:second_topic) { create(:topic, subject: quiz_subject) }

    context "without a daily flag" do
      let!(:challenge) do
        create(:challenge, topic: topic, challenge_type: "number_of_points",
          number_required: 50, end_date: 1.hour.from_now)
      end
      let!(:progress) do
        create(:challenge_progress, progress: 45, challenge: challenge, user: student)
      end
      let(:second_student) { create(:student, school: school) }
      let(:quiz_other_topic) { create(:quiz, subject: quiz_subject, topic: second_topic, user: student) }

      it "adds the earned points to the current progress" do
        described_class.call(quiz_five_points, 2, topic)
        expect(progress.reload.progress).to eq(47)
      end

      it "marks the challenge complete when the points target is reached" do
        described_class.call(quiz_five_points, 5, topic)
        expect(progress.reload.completed).to be true
      end

      it "marks the challenge as awarded when points have been granted" do
        described_class.call(quiz_five_points, 5, topic)
        expect(progress.reload.awarded).to be true
      end

      it "awards points when the challenge is completed" do
        described_class.call(quiz_five_points, 5, topic)
        expect { student.reload }.to change(student, :challenge_points).by(challenge.points)
      end

      it "does not award points to other students" do
        described_class.call(quiz_five_points, 5)
        expect { second_student.reload }.not_to change(second_student, :challenge_points)
      end

      it "does not award when the quiz has no topic" do
        described_class.call(quiz_five_points_lucky_dip, 5)
        expect(progress.reload.awarded).to be false
      end

      it "does not award when the quiz topic does not match the challenge topic" do
        described_class.call(quiz_other_topic, 5)
        expect(progress.reload.awarded).to be false
      end

      it "awards a lucky dip quiz when a matching topic is specified" do
        described_class.call(quiz_five_points_lucky_dip, 5, topic)
        expect(progress.reload.awarded).to be true
      end
    end

    context "with a daily flag" do
      let!(:challenge) do
        create(:challenge, topic: topic, challenge_type: "number_of_points",
          number_required: 50, end_date: 1.hour.from_now, daily: true)
      end
      let!(:progress) do
        create(:challenge_progress, progress: 45, challenge: challenge, user: student)
      end

      it "awards points" do
        described_class.call(quiz_five_points, 5)
        expect { student.reload }.to change(student, :challenge_points).by(challenge.points)
      end

      it "awards a lucky dip quiz regardless of topic" do
        described_class.call(quiz_five_points_lucky_dip, 5, second_topic)
        expect(progress.reload.awarded).to be true
      end
    end
  end
end
