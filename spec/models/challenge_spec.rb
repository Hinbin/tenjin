require 'rails_helper'

RSpec.describe Challenge, type: :model do
  let(:subject) { create(:subject) }
  let(:topic) { create(:topic, subject: subject) }
  let(:different_subject_topic) { create(:topic) }
  let(:challenge_one) { Challenge.create_challenge(topic.subject) }
  let(:challenge_two) { Challenge.create_challenge(topic.subject) }
  let(:challenge_full_marks) { Challenge.create_challenge(topic.subject, 'full_marks') }

  describe '#create_challenge' do
    it 'creates a new challenge for a given subject' do
      expect(Challenge.create_challenge(topic.subject).topic.subject).to eq(subject)
    end

    it 'has the default length of a week' do
      expect(Challenge.create_challenge(topic.subject).end_date).to be_within(1.second).of (DateTime.now + 1.week)
    end

    it 'is created with a random type when one not given' do
      srand(1)
      expect(challenge_one.challenge_type).not_to eq(challenge_two.challenge_type)
    end

    it 'allows me to specify a challenge type' do
      expect(challenge_full_marks.challenge_type).to eq('full_marks')
    end

    it 'doubles the amount of challenge points for a ten out of ten' do
      expect(challenge_full_marks.points).to eq(20)
    end

    it 'throws an error if there are no topics for the subject'
  end

  describe '#stringify' do
    it 'turns a challenge into a string describing the challenge' do
      srand(1)
      expect(Challenge.stringify(challenge_one)).to eq('Obtain a streak of 5 correct answers for ' + topic.name)
    end
  end
end
