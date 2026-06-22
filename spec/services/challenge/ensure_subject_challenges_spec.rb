# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Challenge::EnsureSubjectChallenges, :default_creates do
  let!(:topics) { create_list(:topic, 3, subject:) }

  def subject_challenges
    Challenge.joins(:topic)
             .where(topics: { subject_id: subject.id })
             .where('end_date > ?', Time.current)
  end

  def regular_types
    subject_challenges.where.not(challenge_type: 'daily_devotion').pluck(:challenge_type)
  end

  context 'when a subject has no active challenges' do
    it 'tops the subject up to at least the minimum' do
      described_class.call
      expect(regular_types.length).to be >= described_class::MIN_ACTIVE
    end

    it 'spans every difficulty tier' do
      described_class.call
      described_class::TIERS.each do |tier|
        expect(regular_types & tier).not_to be_empty
      end
    end

    it 'never repeats a challenge type or topic' do
      described_class.call
      regular = subject_challenges.where.not(challenge_type: 'daily_devotion')
      expect(regular.pluck(:challenge_type).uniq.length).to eq(regular.count)
      expect(regular.pluck(:topic_id).uniq.length).to eq(regular.count)
    end

    it 'creates a single global daily_devotion challenge' do
      described_class.call
      expect(Challenge.daily_devotion.count).to eq(1)
    end
  end

  context 'when a subject already meets the minimum' do
    before do
      create_list(:challenge, described_class::MIN_ACTIVE, topic:, end_date: 1.hour.from_now)
      create(:challenge, topic:, challenge_type: 'daily_devotion', end_date: 1.day.from_now)
    end

    it 'adds no further challenges' do
      expect { described_class.call }.not_to change(Challenge, :count)
    end
  end
end
