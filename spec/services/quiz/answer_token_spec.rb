# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Quiz::AnswerToken do
  describe '.for' do
    subject(:token) { described_class.for(quiz_id: 1, question_id: 2, answer_id: 3) }

    it 'is an opaque fixed-length hex token, not the answer id' do
      expect(token).to match(/\A[0-9a-f]{32}\z/)
    end

    it 'is deterministic for the same quiz/question/answer' do
      expect(token).to eq(described_class.for(quiz_id: 1, question_id: 2, answer_id: 3))
    end

    it 'differs per quiz so a saved answer map cannot be replayed next quiz' do
      expect(token).not_to eq(described_class.for(quiz_id: 9, question_id: 2, answer_id: 3))
    end

    it 'differs per answer within the same question' do
      expect(token).not_to eq(described_class.for(quiz_id: 1, question_id: 2, answer_id: 4))
    end
  end

  describe '.valid?' do
    let(:token) { described_class.for(quiz_id: 1, question_id: 2, answer_id: 3) }

    it 'accepts the token for the matching answer' do
      expect(described_class.valid?(token, quiz_id: 1, question_id: 2, answer_id: 3)).to be(true)
    end

    it 'rejects the token against a different answer' do
      expect(described_class.valid?(token, quiz_id: 1, question_id: 2, answer_id: 4)).to be(false)
    end

    it 'rejects a token from a different quiz' do
      expect(described_class.valid?(token, quiz_id: 9, question_id: 2, answer_id: 3)).to be(false)
    end

    it 'rejects a blank token' do
      expect(described_class.valid?('', quiz_id: 1, question_id: 2, answer_id: 3)).to be(false)
      expect(described_class.valid?(nil, quiz_id: 1, question_id: 2, answer_id: 3)).to be(false)
    end
  end
end
