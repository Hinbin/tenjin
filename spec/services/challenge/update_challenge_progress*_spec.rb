require 'rails_helper'

RSpec.describe Challenge::UpdateChallengeProgress, :focus do
  include_context 'default_creates'

  let(:quiz_full_marks) { create(:quiz, subject: subject, num_questions_asked: 10, answered_correct: 10) }
  let(:quiz_7_out_of_10) { create(:quiz, subject: subject, num_questions_asked: 10, answered_correct: 7) }
  let(:quiz_1_out_of_3) { create(:quiz, subject: subject, num_questions_asked: 3, answered_correct: 1) }
  let(:challenge_full_marks) do
    create(:challenge, topic: topic, challenge_type: 'full_marks', end_date: DateTime.now + 1.hour)
  end

  context 'when updating a challenge' do
    before do
      challenge_full_marks
    end

    it 'flags challenge as complete if full marks have been obtained' do
      described_class.new(quiz_full_marks).call
      expect(ChallengeProgress.first.completed).to eq(true)
    end

    it 'sets progress to the highest percentage achieved' do
      described_class.new(quiz_7_out_of_10).call
      expect(ChallengeProgress.first.progress).to eq(70)
    end

    it 'ignores progress that is less than current progress' do
      described_class.new(quiz_full_marks).call
      described_class.new(quiz_7_out_of_10).call
      expect(ChallengeProgress.first.progress).to eq(100)
    end

    it 'handles fractions for progress' do
      described_class.new(quiz_1_out_of_3).call
      expect(ChallengeProgress.first.progress).to eq(33)
    end
  end
end
