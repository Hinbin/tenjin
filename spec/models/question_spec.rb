# frozen_string_literal: true

require 'rails_helper'
require 'support/session_helpers'

RSpec.describe Question, :default_creates, type: :model do
  let(:mismatched_question) { build(:question, lesson: create(:lesson), topic: topic) }

  context 'with validations' do
    subject { build(:question) }

    it { is_expected.to belong_to(:topic) }
    it { is_expected.to have_many(:answers) }
    it { is_expected.to belong_to(:lesson).optional }
  end

  it 'does not allow a mismatched lesson and topic' do
    expect(mismatched_question).not_to be_valid
  end

  it 'deletes answers when being deleted' do
    question
    expect { question.destroy }.to change(described_class, :count).by(-1)
  end

  describe '.check_short_answer' do
    let(:question) { create(:question, question_type: 'multiple') }
    let(:answer) { create(:answer, question: question, correct: false) }

    context 'when switching a question to a short answer question' do
      it 'changes all existing answers to be correct' do
        answer
        question.update_attribute(:question_type, 'short_answer')
        expect(Answer.first.correct).to eq(true)
      end
    end
  end
end
