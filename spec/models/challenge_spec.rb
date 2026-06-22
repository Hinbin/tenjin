# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Challenge, type: :model do
  let(:subject) { create(:subject) }
  let(:topic) { create(:topic, subject: subject) }
  let(:different_subject_topic) { create(:topic) }
  let(:challenge_one) { described_class.create_challenge(topic.subject) }
  let(:challenge_two) { described_class.create_challenge(topic.subject) }
  let(:challenge_full_marks) do
    create(:challenge, topic: topic, challenge_type: 'number_correct',
                       number_required: 10, end_date: Time.now + 1.hour)
  end

  describe '#create_challenge' do
    it 'creates a new challenge for a given subject' do
      expect(described_class.create_challenge(topic.subject).topic.subject).to eq(subject)
    end

    it 'has the default length of a week' do
      expect(described_class.create_challenge(topic.subject).end_date).to be_within(1.second).of(Time.now.utc + 1.week)
    end

    it 'is created with a random type when one not given' do
      srand(1)
      expect(challenge_one.challenge_type).not_to eq(challenge_two.challenge_type)
    end

    it 'allows me to specify a challenge type' do
      expect(challenge_full_marks.challenge_type).to eq('number_correct')
    end

    it 'doubles the points with a x2 multiplier' do
      challenge = described_class.create_challenge(topic.subject, 'number_correct', multiplier: 2)
      expect(challenge.points).to eq(20 * challenge.number_required)
    end

    it 'allows me to specify a duration' do
      srand(1)
      expect(described_class.create_challenge(topic.subject, duration: 3.days).end_date)
        .to be_within(1.second).of(Time.now + 3.days)
    end

    it 'allows me to specify a duration in hours' do
      srand(1)
      expect(described_class.create_challenge(topic.subject, duration: 36.hours).end_date)
        .to be_within(1.second).of(Time.now + 36.hours)
    end

    it 'scales points by number_required for a x1 multiplier' do
      challenge = described_class.create_challenge(topic.subject, 'streak')
      expect(challenge.points).to eq(15 * challenge.number_required)
    end

    it 'awards a flat reward for a perfect quiz challenge' do
      challenge = described_class.create_challenge(topic.subject, 'perfect_quiz')
      expect(challenge.points).to eq(Challenge::PERFECT_QUIZ_POINTS)
    end

    it 'creates a daily challenge' do
      srand(1)
      expect(described_class.create_challenge(topic.subject, daily: true).daily).to eq(true)
    end
  end

  describe '#stringify' do
    it 'describes a topic-bound challenge with its topic and subject' do
      challenge = create(:challenge, topic:, challenge_type: 'streak', number_required: 5)
      expect(challenge.stringify)
        .to eq("Obtain a streak of 5 correct answers in #{topic.name} for #{topic.subject.name}")
    end

    it 'describes a daily_devotion challenge without a topic, since it is global' do
      challenge = create(:challenge, topic:, challenge_type: 'daily_devotion', number_required: 3)
      expect(challenge.stringify).to eq('Play on 3 days in a row')
    end
  end
end
