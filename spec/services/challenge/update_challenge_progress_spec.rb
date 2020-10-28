# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Challenge::UpdateChallengeProgress, default_creates: true do
  context 'when updating a number correct challenge' do
    before do
      challenge_full_marks
    end

    let(:quiz_full_marks) do
      create(:quiz, subject: subject, topic: topic, num_questions_asked: 10,
                    answered_correct: 10, active: false, user: student)
    end

    let(:quiz_7_out_of_10) do
      create(:quiz, subject: subject, topic: topic, num_questions_asked: 10,
                    answered_correct: 7, active: false, user: student)
    end
    let(:quiz_1_out_of_3) do
      create(:quiz, subject: subject, topic: topic, num_questions_asked: 3,
                    answered_correct: 1, active: false, user: student)
    end
    let(:challenge_full_marks) do
      create(:challenge, topic: topic, challenge_type: 'number_correct',
                         number_required: 10, end_date: Time.now + 1.hour)
    end

    it 'flags challenge as complete if the required number of questions have been answered correctly' do
      described_class.new(quiz_full_marks).call
      expect(ChallengeProgress.first.completed).to eq(true)
    end

    it 'sets progress to the highest percentage achieved' do
      described_class.new(quiz_7_out_of_10).call
      expect(ChallengeProgress.first.progress).to eq(7)
    end

    it 'ignores progress that is less than current progress' do
      described_class.new(quiz_full_marks).call
      described_class.new(quiz_7_out_of_10).call
      expect(ChallengeProgress.first.progress).to eq(10)
    end

    it 'awards points after the challenge is complete' do
      described_class.new(quiz_full_marks).call
      expect { student.reload }.to change(student, :challenge_points).by(challenge_full_marks.points)
    end

    it 'only updates the streak progress for the topic of the challenge' do
      challenge_different_topic = create(:challenge, topic: create(:topic, subject: subject),
                                                     challenge_type: 'number_correct', number_required: 3,
                                                     end_date: Time.now + 1.hour)
      expect { described_class.new(quiz_full_marks, 'number_correct').call }
        .to change { ChallengeProgress.where(challenge: challenge_different_topic).count }.by(0)
    end

    it 'only adds challenge points once' do
      described_class.new(quiz_full_marks).call
      described_class.new(quiz_full_marks).call
      expect(ChallengeProgress.first.progress).to eq(10)
    end
  end

  context 'when updating a 5 streak challenge' do
    let(:quiz_streak_of_five) { create(:quiz, subject: subject, user: student, topic: topic, streak: 5) }
    let(:quiz_streak_of_three) { create(:quiz, subject: subject, user: student, topic: topic, streak: 3) }
    let(:challenge_streak_of_five) do
      create(:challenge, topic: topic, challenge_type: 'streak', number_required: 5, end_date: Time.now + 1.hour)
    end
    let(:completed_challenge_progress) do
      create(:challenge_progress, challenge: challenge_streak_of_five, user: student, completed: true, awarded: true)
    end

    before do
      challenge_streak_of_five
    end

    it 'flags challenge as complete when a streak of 5 is obtained' do
      described_class.new(quiz_streak_of_five).call
      expect(ChallengeProgress.first.completed).to eq(true)
    end

    it 'sets progress as highest acheived' do
      described_class.new(quiz_streak_of_three).call
      expect(ChallengeProgress.first.progress).to eq(3)
    end

    it 'awards points after the challenge is complete' do
      described_class.new(quiz_streak_of_five).call
      expect { student.reload }.to change(student, :challenge_points).by(challenge_streak_of_five.points)
    end

    it 'only adds the challenge points once' do
      completed_challenge_progress
      described_class.new(quiz_streak_of_five).call
      expect { student.reload }.to change(student, :challenge_points).by(0)
    end

    it 'does not set completed back to false' do
      completed_challenge_progress
      described_class.new(quiz_streak_of_three).call
      expect(ChallengeProgress.first.completed).to eq(true)
    end
  end

  context 'when updating a number of points challenge' do
    let(:quiz_five_points) { create(:quiz, subject: subject, topic: topic, user: student) }
    let(:quiz_five_points_lucky_dip) { create(:quiz, subject: subject, topic: nil, user: student) }

    let(:second_topic) { create(:topic, subject: subject) }

    context 'without a daily flag' do
      let(:challenge_get_fifty_points) do
        create(:challenge, topic: topic, challenge_type: 'number_of_points',
                           number_required: 50, end_date: Time.now + 1.hour)
      end

      let(:nearly_complete_fifty_point_progress) do
        create(:challenge_progress, progress: 45, challenge: challenge_get_fifty_points, user: student)
      end

      before do
        nearly_complete_fifty_point_progress
      end

      it 'increases the progress by the correct amount' do
        described_class.new(quiz_five_points, 2, topic).call
        expect(ChallengeProgress.first.progress).to eq(47)
      end

      it 'flags challenge as complete when 5 points are obtained' do
        described_class.new(quiz_five_points, 5, topic).call
        expect(ChallengeProgress.first.completed).to eq(true)
      end

      it 'flags challenge as awarded when points have been awarded' do
        described_class.new(quiz_five_points, 5, topic).call
        expect(ChallengeProgress.first.awarded).to eq(true)
      end

      it 'awards points after the challenge is complete' do
        described_class.new(quiz_five_points, 5, topic).call
        expect { student.reload }.to change(student, :challenge_points).by(challenge_get_fifty_points.points)
      end

      it 'only updates the challenge progress for the current user' do
        second_student = create(:student, school: school)
        described_class.new(quiz_five_points, 5).call
        expect { student.reload }.to change(second_student, :challenge_points).by(0)
      end

      it 'only updates the challenge if the question matches its topic with a lucky dip' do
        described_class.new(quiz_five_points_lucky_dip, 5).call
        expect(ChallengeProgress.first.awarded).to eq(false)
      end

      it 'only updates the challenge if the question matches its topic' do
        quiz_five_points_other_topic = create(:quiz, subject: subject, topic: second_topic, user: student)
        described_class.new(quiz_five_points_other_topic, 5).call
        expect(ChallengeProgress.first.awarded).to eq(false)
      end

      it 'updates the challenge if it is a lucky dip quiz' do
        described_class.new(quiz_five_points_lucky_dip, 5, topic).call
        expect(ChallengeProgress.first.awarded).to eq(true)
      end
    end

    context 'with a daily flag' do
      let(:challenge_get_fifty_points_daily) do
        create(:challenge, topic: topic, challenge_type: 'number_of_points',
                           number_required: 50, end_date: Time.now + 1.hour, daily: true)
      end
      let(:nearly_complete_fifty_point_progress_daily) do
        create(:challenge_progress, progress: 45, challenge: challenge_get_fifty_points_daily, user: student)
      end

      before do
        nearly_complete_fifty_point_progress_daily
      end

      it 'awards points' do
        described_class.new(quiz_five_points, 5).call
        expect { student.reload }.to change(student, :challenge_points).by(challenge_get_fifty_points_daily.points)
      end

      it 'awards points with a lucky dip quiz for a question on a different topic' do
        described_class.new(quiz_five_points_lucky_dip, 5, second_topic).call
        expect(ChallengeProgress.first.awarded).to eq(true)
      end
    end
  end
end
