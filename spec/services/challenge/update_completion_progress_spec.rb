# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Challenge::UpdateCompletionProgress, :default_creates do
  let(:quiz) { create(:quiz, subject:, topic:, user: student, active: false) }

  context 'when updating a perfect quiz challenge' do
    let(:challenge_perfect) do
      create(:challenge, topic:, challenge_type: 'perfect_quiz', number_required: 5, end_date: 1.hour.from_now)
    end

    before { challenge_perfect }

    it 'completes on a flawless quiz of at least the required length' do
      allow(quiz).to receive_messages(accuracy_percent: 100, total_questions: 8)
      described_class.new(quiz).call
      expect(ChallengeProgress.find_by(challenge: challenge_perfect).completed).to be(true)
    end

    it 'does not complete when the quiz is not flawless' do
      allow(quiz).to receive_messages(accuracy_percent: 80, total_questions: 8)
      described_class.new(quiz).call
      expect(ChallengeProgress.find_by(challenge: challenge_perfect).completed).to be(false)
    end

    it 'does not complete a flawless quiz shorter than the requirement' do
      allow(quiz).to receive_messages(accuracy_percent: 100, total_questions: 3)
      described_class.new(quiz).call
      expect(ChallengeProgress.find_by(challenge: challenge_perfect).completed).to be(false)
    end
  end

  context 'when updating a complete quizzes challenge' do
    let(:challenge_complete) do
      create(:challenge, topic:, challenge_type: 'complete_quizzes', number_required: 2, end_date: 1.hour.from_now)
    end

    before { challenge_complete }

    it 'increments once per finished quiz and completes at the target' do
      described_class.new(quiz).call
      described_class.new(quiz).call
      expect(ChallengeProgress.first).to have_attributes(progress: 2, completed: true)
    end
  end

  context 'when updating a daily devotion challenge' do
    let(:challenge_devotion) do
      create(:challenge, topic:, challenge_type: 'daily_devotion', number_required: 3, end_date: 1.hour.from_now)
    end

    before do
      create(:enrollment, user: student, classroom:)
      challenge_devotion
      student.update(streak_days: 3)
    end

    it 'completes from the global play-day streak even on a quiz in another subject' do
      other_quiz = create(:quiz, subject: create(:subject), user: student)
      described_class.new(other_quiz).call
      expect(ChallengeProgress.find_by(challenge: challenge_devotion).completed).to be(true)
    end

    it 'awards the points once the streak target is met' do
      expect { described_class.new(quiz).call }
        .to change { student.reload.challenge_points.to_i }.by(challenge_devotion.points)
    end
  end
end
