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

    it "marks the challenge complete and awards points at full marks" do
      expect { described_class.call(quiz_full_marks) }
        .to change { student.reload.challenge_points }.by(challenge.points)
      expect(progress).to be_completed
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

    it "marks the challenge complete and awards points when the streak target is reached" do
      expect { described_class.call(quiz_streak_of_five) }
        .to change { student.reload.challenge_points }.by(challenge.points)
      expect(progress).to be_completed
    end

    it "records the highest streak as progress" do
      described_class.call(quiz_streak_of_three)
      expect(progress.progress).to eq(3)
    end

    context "with an already-completed progress record" do
      let!(:completed_progress) do
        create(:challenge_progress, challenge: challenge, user: student, completed: true, awarded: true)
      end

      it "does not award points a second time" do
        expect { described_class.call(quiz_streak_of_five) }
          .not_to(change { student.reload.challenge_points })
      end

      it "does not reset completed to false after a lower streak" do
        described_class.call(quiz_streak_of_three)
        expect(completed_progress.reload).to be_completed
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
      let(:quiz_other_topic) { create(:quiz, subject: quiz_subject, topic: second_topic, user: student) }

      it "adds the earned points to the current progress" do
        described_class.call(quiz_five_points, 2, topic)
        expect(progress.reload.progress).to eq(47)
      end

      it "completes the challenge, marks it awarded, and grants points" do
        expect { described_class.call(quiz_five_points, 5, topic) }
          .to change { student.reload.challenge_points }.by(challenge.points)
        expect(progress.reload).to have_attributes(completed: true, awarded: true)
      end

      it "does not award when the quiz has no topic" do
        described_class.call(quiz_five_points_lucky_dip, 5)
        expect(progress.reload).not_to be_awarded
      end

      it "does not award when the quiz topic does not match the challenge topic" do
        described_class.call(quiz_other_topic, 5)
        expect(progress.reload).not_to be_awarded
      end

      it "awards a lucky dip quiz when a matching topic is specified" do
        described_class.call(quiz_five_points_lucky_dip, 5, topic)
        expect(progress.reload).to be_awarded
      end

      context "with another student in the school" do
        let!(:other_student) { create(:student, school: school) }

        it "does not award points to them" do
          expect { described_class.call(quiz_five_points, 5) }
            .not_to(change { other_student.reload.challenge_points })
        end
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
        expect { described_class.call(quiz_five_points, 5) }
          .to change { student.reload.challenge_points }.by(challenge.points)
      end

      it "awards a lucky dip quiz regardless of topic" do
        described_class.call(quiz_five_points_lucky_dip, 5, second_topic)
        expect(progress.reload).to be_awarded
      end
    end
  end
end
