require 'rails_helper'

RSpec.describe Challenge, type: :model do
  let(:subject) { create(:subject) }
  let(:topic) { create(:topic, subject: subject) }
  let(:different_subject_topic) { create(:topic) }
  let(:challenge_one) { Challenge.create_challenge(topic.subject) }
  let(:challenge_two) { Challenge.create_challenge(topic.subject) }
  let(:challenge_full_marks) do
    create(:challenge, topic: topic, challenge_type: 'number_correct',
                       number_required: 10, end_date: DateTime.now + 1.hour)
  end

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
      expect(challenge_full_marks.challenge_type).to eq('number_correct')
    end
  end

  describe '#stringify' do
    it 'turns a challenge into a string describing the challenge' do
      srand(1)
      expect(Challenge.stringify(challenge_one)).to eq('Obtain a streak of ' +
        challenge_one.number_required.to_s + ' correct answers for ' + topic.name)
    end
  end
end
