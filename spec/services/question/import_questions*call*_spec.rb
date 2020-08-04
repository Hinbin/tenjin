# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Question::ImportQuestions, '#call', default_creates: true do
  context 'when importing questions' do
    let(:question_hash) do
      { question_type: 'multiple',
        question_text: { body: FFaker::Lorem.sentence },
        answers: [
          { text: FFaker::Lorem.sentence, correct: true },
          { text: FFaker::Lorem.sentence, correct: false },
          { text: FFaker::Lorem.sentence, correct: false }
        ],
        lesson: { title: FFaker::Lorem.word } }
    end

    let(:valid_hash) do
      Array.new(rand(1..10)) { question_hash }
    end

    it 'validates questions successfully' do
      result = described_class.new(JSON.generate(valid_hash), topic).call
      expect(result.success?).to eq(true)
    end

    it 'reports number of questions added' do
      result = described_class.new(JSON.generate(valid_hash), topic).call
      expect(result.number_questions_imported).to eq(valid_hash.length)
    end

    it 'saves questions to the database' do
      described_class.new(JSON.generate(valid_hash), topic).call
      expect(Question.count).to eq(valid_hash.length)
    end

    it 'saves answers to the database' do
      described_class.new(JSON.generate(valid_hash), topic).call
      expect(Answer.count).to eq(valid_hash.length * 3)
    end

    it 'fails validation for missing question type' do
      valid_hash[0] = valid_hash[0].except(:question_type)
      result = described_class.new(JSON.generate(valid_hash), topic).call
      expect(result.success?).to eq(false)
    end

    it 'fails validation for missing question text body' do
      valid_hash[0]['question_text'] = ''
      result = described_class.new(JSON.generate(valid_hash), topic).call
      expect(result.success?).to eq(false)
    end
end
