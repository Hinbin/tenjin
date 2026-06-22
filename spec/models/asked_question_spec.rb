# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AskedQuestion do
  describe '.fast_flag_counts' do
    let(:student) { create(:student) }
    let(:other_student) { create(:student) }
    let(:quiz) { create(:quiz, user: student) }

    it 'counts recent flagged-fast answers per user' do
      create(:asked_question, quiz: quiz, user: student, flagged_fast: true)
      create(:asked_question, quiz: quiz, user: student, flagged_fast: true)
      create(:asked_question, quiz: quiz, user: student, flagged_fast: false)

      expect(described_class.fast_flag_counts([student.id])).to eq(student.id => 2)
    end

    it 'ignores flags older than the window' do
      create(:asked_question, quiz: quiz, user: student, flagged_fast: true, created_at: 30.days.ago)

      expect(described_class.fast_flag_counts([student.id])).to eq({})
    end

    it 'only counts the requested users' do
      create(:asked_question, quiz: quiz, user: student, flagged_fast: true)

      expect(described_class.fast_flag_counts([other_student.id])).to eq({})
    end
  end
end
