require 'rails_helper'

RSpec.describe Challenge::UpdateChallengeProgress do
  include_context 'default_creates'

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
                         number_required: 10, end_date: DateTime.now + 1.hour)
    end
    let(:challenge_three_marks) do
      create(:challenge, topic: topic, challenge_type: 'number_correct',
                         number_required: 3, end_date: DateTime.now + 1.hour)
    end
    let(:challenge_different_topic) do
      create(:challenge, topic: create(:topic, subject: subject), challenge_type: 'number_correct',
                         number_required: 3, end_date: DateTime.now + 1.hour)
    end

    it 'flags challenge as complete if the required number of questions have been answered correctly' do
      described_class.new(quiz_full_marks, 'number_correct').call
      expect(ChallengeProgress.first.completed).to eq(true)
    end

    it 'sets progress to the highest percentage achieved' do
      described_class.new(quiz_7_out_of_10, 'number_correct').call
      expect(ChallengeProgress.first.progress).to eq(70)
    end

    it 'ignores progress that is less than current progress' do
      described_class.new(quiz_full_marks, 'number_correct').call
      described_class.new(quiz_7_out_of_10, 'number_correct').call
      expect(ChallengeProgress.first.progress).to eq(100)
    end

    it 'handles fractions for progress' do
      challenge_three_marks
      described_class.new(quiz_1_out_of_3, 'number_correct').call
      expect(ChallengeProgress.where(challenge: challenge_three_marks).first.progress).to eq(33)
    end

    it 'awards points after the challenge is complete' do
      described_class.new(quiz_full_marks, 'number_correct').call
      expect(ChallengeProgress.first.user.challenge_points).to eq(challenge_full_marks.points)
    end

    it 'only updates the streak progress for the topic of the challenge' do
      challenge_different_topic
      described_class.new(quiz_full_marks, 'number_correct').call
      expect(ChallengeProgress.where(challenge: challenge_different_topic).first.completed).to eq(false)
    end
  end

  context 'when updating a 5 streak challenge' do
    let(:quiz_streak_of_five) { create(:quiz, subject: subject, topic: topic, streak: 5) }
    let(:quiz_streak_of_three) { create(:quiz, subject: subject, topic: topic, streak: 3) }
    let(:challenge_streak_of_five) do
      create(:challenge, topic: topic, challenge_type: 'streak', number_required: 5, end_date: DateTime.now + 1.hour)
    end
    let(:completed_challenge_progress) do
      create(:challenge_progress, challenge: challenge_streak_of_five, completed: true)
    end

    before do
      challenge_streak_of_five
    end

    it 'flags challenge as complete when a streak of 5 is obtained' do
      described_class.new(quiz_streak_of_five, 'streak').call
      expect(ChallengeProgress.first.completed).to eq(true)
    end

    it 'sets progress as highest percentage acheived' do
      described_class.new(quiz_streak_of_three, 'streak').call
      expect(ChallengeProgress.first.progress).to eq(60)
    end

    it 'awards points after the challenge is complete' do
      described_class.new(quiz_streak_of_five, 'streak').call
      expect(ChallengeProgress.first.user.challenge_points).to eq(challenge_streak_of_five.points)
    end

    it 'only adds the challenge points once' do
      completed_challenge_progress
      described_class.new(quiz_streak_of_five, 'streak').call
      expect(ChallengeProgress.first.user.challenge_points).to eq(0)
    end
  end

  context 'when updating a number of points challenge' do
    let(:challenge_get_fifty_points) do
      create(:challenge, topic: topic, challenge_type: 'number_of_points',
                         number_required: 50, end_date: DateTime.now + 1.hour)
    end
    let(:nearly_complete_fifty_point_progress) do
      create(:challenge_progress, progress: 45, challenge: challenge_get_fifty_points, user: student)
    end
    let(:quiz_five_points) { create(:quiz, subject: subject, topic: topic, user: student) }

    before do
      nearly_complete_fifty_point_progress
    end

    it 'increases the progress by the correct amount' do
      described_class.new(quiz_five_points, 'number_of_points', 2, topic).call
      expect(ChallengeProgress.first.progress).to eq(47)
    end

    it 'flags challenge as complete when a streak of 5 is obtained' do
      described_class.new(quiz_five_points, 'number_of_points', 5, topic).call
      expect(ChallengeProgress.first.completed).to eq(true)
    end
  end
end
