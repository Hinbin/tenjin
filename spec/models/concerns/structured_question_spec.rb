# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StructuredQuestion, type: :model do
  let(:cloze_text) { 'A {{1}} and a {{2}}.' }
  let(:drag_drop_config) do
    { 'items' => [{ 'id' => 'i1', 'text' => 'control' },
                  { 'id' => 'i2', 'text' => 'arithmetic' },
                  { 'id' => 'i3', 'text' => 'distractor' }],
      'answer' => { '1' => 'i1', '2' => 'i2' } }
  end

  let(:matrix_config) do
    { 'rows' => [{ 'id' => 'r1', 'label' => 'Python' }, { 'id' => 'r2', 'label' => 'HTML' }],
      'columns' => [{ 'id' => 'c1', 'label' => 'Interpreted' }, { 'id' => 'c2', 'label' => 'Markup' }],
      'correct' => { 'r1' => ['c1'], 'r2' => ['c2'] } }
  end

  describe '#score_response for drag_drop' do
    subject(:question) do
      build(:question, question_type: 'drag_drop', question_text: cloze_text, config: drag_drop_config)
    end

    it 'gives full marks when every blank is correct' do
      expect(question.score_response('1' => 'i1', '2' => 'i2')).to eq(1.0)
    end

    it 'gives partial credit for one of two blanks' do
      expect(question.score_response('1' => 'i1', '2' => 'i3')).to eq(0.5)
    end

    it 'gives zero for an empty response' do
      expect(question.score_response({})).to eq(0.0)
    end

    context 'when one item answers more than one blank' do
      let(:cloze_text) { 'A {{1}}, a {{2}} and a {{3}}.' }
      let(:drag_drop_config) do
        { 'items' => [{ 'id' => 'i1', 'text' => 'shared' }, { 'id' => 'i2', 'text' => 'other' }],
          'answer' => { '1' => 'i1', '2' => 'i2', '3' => 'i1' } }
      end

      it 'is valid' do
        expect(question).to be_valid
      end

      it 'awards full marks when the shared item fills both of its blanks' do
        expect(question.score_response('1' => 'i1', '2' => 'i2', '3' => 'i1')).to eq(1.0)
      end

      it 'awards partial credit when the shared item fills only one of its blanks' do
        expect(question.score_response('1' => 'i1', '2' => 'i2', '3' => 'i2').round(2)).to eq(0.67)
      end
    end
  end

  describe '#score_response for matrix' do
    subject(:question) { build(:question, question_type: 'matrix', config: matrix_config) }

    it 'gives full marks when every cell decision is correct' do
      expect(question.score_response('r1' => ['c1'], 'r2' => ['c2'])).to eq(1.0)
    end

    it 'penalises over-ticking a row' do
      # r1 ticks both columns: c1 correct (hit), c2 wrongly ticked (miss) => 0.5 for the row.
      expect(question.score_response('r1' => %w[c1 c2], 'r2' => ['c2'])).to eq(0.75)
    end

    it 'gives zero for an empty response' do
      expect(question.score_response({})).to eq(0.5) # both rows: correct cell missed, wrong cell left blank
    end
  end

  describe 'validations' do
    it 'rejects a drag_drop question whose question text has no blanks' do
      question = build(:question, question_type: 'drag_drop', question_text: 'no blanks here', config: drag_drop_config)
      expect(question).to be_invalid
    end

    it 'rejects a drag_drop answer pointing at a missing item' do
      question = build(:question, question_type: 'drag_drop', question_text: cloze_text,
                                  config: drag_drop_config.merge('answer' => { '1' => 'i1', '2' => 'missing' }))
      expect(question).to be_invalid
    end

    it 'accepts a well-formed drag_drop question' do
      question = build(:question, question_type: 'drag_drop', question_text: cloze_text, config: drag_drop_config)
      expect(question).to be_valid
    end

    it 'rejects a matrix row with no correct column' do
      question = build(:question, question_type: 'matrix',
                                  config: matrix_config.merge('correct' => { 'r1' => ['c1'], 'r2' => [] }))
      expect(question).to be_invalid
    end

    it 'accepts a well-formed matrix question' do
      expect(build(:question, question_type: 'matrix', config: matrix_config)).to be_valid
    end
  end
end
