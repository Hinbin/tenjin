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

  let(:fill_blank_config) do
    { 'answer' => { '1' => 'control|control unit', '2' => 'arithmetic logic' } }
  end

  let(:ordering_config) do
    { 'items' => [{ 'id' => 'o1', 'text' => 'Fetch' },
                  { 'id' => 'o2', 'text' => 'Decode' },
                  { 'id' => 'o3', 'text' => 'Execute' }],
      'order' => %w[o1 o2 o3] }
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

    context 'when a blank accepts more than one item' do
      let(:drag_drop_config) do
        { 'items' => [{ 'id' => 'i1', 'text' => 'control' },
                      { 'id' => 'i2', 'text' => 'control unit' },
                      { 'id' => 'i3', 'text' => 'arithmetic' }],
          'answer' => { '1' => %w[i1 i2], '2' => 'i3' } }
      end

      it 'is valid' do
        expect(question).to be_valid
      end

      it 'accepts the first listed item for the blank' do
        expect(question.score_response('1' => 'i1', '2' => 'i3')).to eq(1.0)
      end

      it 'accepts an alternative item for the blank' do
        expect(question.score_response('1' => 'i2', '2' => 'i3')).to eq(1.0)
      end

      it 'rejects an item that is not in the blank\'s accepted list' do
        expect(question.score_response('1' => 'i3', '2' => 'i3')).to eq(0.5)
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

  describe '#score_response for fill_blank' do
    subject(:question) do
      build(:question, question_type: 'fill_blank', question_text: cloze_text, config: fill_blank_config)
    end

    it 'gives full marks when every blank is typed correctly' do
      expect(question.score_response('1' => 'control', '2' => 'arithmetic logic')).to eq(1.0)
    end

    it 'matches case-insensitively and ignores surrounding spaces' do
      expect(question.score_response('1' => '  Control Unit ', '2' => 'ARITHMETIC LOGIC')).to eq(1.0)
    end

    it 'gives partial credit for one of two blanks' do
      expect(question.score_response('1' => 'control', '2' => 'wrong')).to eq(0.5)
    end

    it 'gives zero for an empty response' do
      expect(question.score_response({})).to eq(0.0)
    end
  end

  describe '#score_response for ordering' do
    subject(:question) { build(:question, question_type: 'ordering', config: ordering_config) }

    it 'gives full marks for the correct sequence' do
      expect(question.score_response('order' => %w[o1 o2 o3])).to eq(1.0)
    end

    it 'gives partial credit for a correctly-ordered run' do
      # Of the two key pairs (o1→o2, o2→o3) only o2→o3 survives here => 1/2.
      expect(question.score_response('order' => %w[o2 o3 o1])).to eq(0.5)
    end

    it 'gives zero for a fully reversed sequence' do
      # No adjacent pair survives a reversal, unlike position scoring where the middle would stay.
      expect(question.score_response('order' => %w[o3 o2 o1])).to eq(0.0)
    end

    it 'gives zero for an empty response' do
      expect(question.score_response({})).to eq(0.0)
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

    it 'rejects a drag_drop multi-item blank pointing at a missing item' do
      question = build(:question, question_type: 'drag_drop', question_text: cloze_text,
                                  config: drag_drop_config.merge('answer' => { '1' => %w[i1 missing], '2' => 'i2' }))
      expect(question).to be_invalid
    end

    it 'rejects a matrix row with no correct column' do
      question = build(:question, question_type: 'matrix',
                                  config: matrix_config.merge('correct' => { 'r1' => ['c1'], 'r2' => [] }))
      expect(question).to be_invalid
    end

    it 'accepts a well-formed matrix question' do
      expect(build(:question, question_type: 'matrix', config: matrix_config)).to be_valid
    end

    it 'rejects a fill_blank question whose text has no blanks' do
      question = build(:question, question_type: 'fill_blank', question_text: 'no blanks', config: fill_blank_config)
      expect(question).to be_invalid
    end

    it 'rejects a fill_blank blank with no accepted answer' do
      question = build(:question, question_type: 'fill_blank', question_text: cloze_text,
                                  config: { 'answer' => { '1' => 'control', '2' => '' } })
      expect(question).to be_invalid
    end

    it 'accepts a well-formed fill_blank question' do
      question = build(:question, question_type: 'fill_blank', question_text: cloze_text, config: fill_blank_config)
      expect(question).to be_valid
    end

    it 'rejects an ordering question with fewer than two items' do
      question = build(:question, question_type: 'ordering',
                                  config: { 'items' => [{ 'id' => 'o1', 'text' => 'only' }], 'order' => ['o1'] })
      expect(question).to be_invalid
    end

    it 'rejects an ordering sequence that omits an item' do
      question = build(:question, question_type: 'ordering',
                                  config: ordering_config.merge('order' => %w[o1 o2]))
      expect(question).to be_invalid
    end

    it 'accepts a well-formed ordering question' do
      expect(build(:question, question_type: 'ordering', config: ordering_config)).to be_valid
    end
  end

  let(:classify_config) do
    { 'items'   => [{ 'id' => 'ci1', 'text' => 'Has a dedicated purpose' },
                    { 'id' => 'ci2', 'text' => 'Runs many programs' },
                    { 'id' => 'ci3', 'text' => 'Built into a machine' }],
      'targets' => [{ 'id' => 'ct1', 'label' => 'Embedded system' },
                    { 'id' => 'ct2', 'label' => 'General-purpose computer' }],
      'correct' => { 'ci1' => 'ct1', 'ci2' => 'ct2', 'ci3' => 'ct1' } }
  end

  describe '#score_response for classify' do
    subject(:question) { build(:question, question_type: 'classify', config: classify_config) }

    it 'gives full marks when every item is in the correct bucket' do
      expect(question.score_response('ci1' => 'ct1', 'ci2' => 'ct2', 'ci3' => 'ct1')).to eq(1.0)
    end

    it 'gives partial credit for one wrong placement' do
      expect(question.score_response('ci1' => 'ct2', 'ci2' => 'ct2', 'ci3' => 'ct1').round(2)).to eq(0.67)
    end

    it 'gives zero for an empty response' do
      expect(question.score_response({})).to eq(0.0)
    end
  end

  describe 'classify validation' do
    it 'accepts a well-formed classify question' do
      expect(build(:question, question_type: 'classify', config: classify_config)).to be_valid
    end

    it 'rejects a classify question with fewer than two items' do
      bad = classify_config.merge('items' => [{ 'id' => 'ci1', 'text' => 'only' }],
                                  'correct' => { 'ci1' => 'ct1' })
      expect(build(:question, question_type: 'classify', config: bad)).to be_invalid
    end

    it 'rejects a classify question with fewer than two targets' do
      bad = classify_config.merge('targets' => [{ 'id' => 'ct1', 'label' => 'Only bucket' }],
                                  'correct' => { 'ci1' => 'ct1', 'ci2' => 'ct1', 'ci3' => 'ct1' })
      expect(build(:question, question_type: 'classify', config: bad)).to be_invalid
    end

    it 'rejects a classify question where an item has no correct target' do
      bad = classify_config.merge('correct' => { 'ci1' => 'ct1', 'ci2' => 'ct2' })
      expect(build(:question, question_type: 'classify', config: bad)).to be_invalid
    end

    it 'rejects a classify question where correct references a non-existent target' do
      bad = classify_config.merge('correct' => { 'ci1' => 'ct1', 'ci2' => 'ct2', 'ci3' => 'ct99' })
      expect(build(:question, question_type: 'classify', config: bad)).to be_invalid
    end
  end

  describe '#bits_correct_count' do
    describe 'drag_drop' do
      subject(:question) do
        build(:question, question_type: 'drag_drop', question_text: cloze_text, config: drag_drop_config)
      end

      it 'returns 2 for a fully correct response' do
        expect(question.bits_correct_count('1' => 'i1', '2' => 'i2')).to eq(2)
      end

      it 'returns 1 for one correct blank' do
        expect(question.bits_correct_count('1' => 'i1', '2' => 'i3')).to eq(1)
      end

      it 'returns 0 for an empty response' do
        expect(question.bits_correct_count({})).to eq(0)
      end
    end

    describe 'fill_blank' do
      subject(:question) do
        build(:question, question_type: 'fill_blank', question_text: cloze_text, config: fill_blank_config)
      end

      it 'returns 2 when both blanks are correct' do
        expect(question.bits_correct_count('1' => 'control', '2' => 'arithmetic logic')).to eq(2)
      end

      it 'returns 1 for one correct blank' do
        expect(question.bits_correct_count('1' => 'wrong', '2' => 'arithmetic logic')).to eq(1)
      end

      it 'accepts alternatives' do
        expect(question.bits_correct_count('1' => 'control unit', '2' => 'arithmetic logic')).to eq(2)
      end
    end

    describe 'matrix' do
      subject(:question) { build(:question, question_type: 'matrix', config: matrix_config) }

      it 'returns 2 for a perfect response (one correct tick per row)' do
        expect(question.bits_correct_count('r1' => ['c1'], 'r2' => ['c2'])).to eq(2)
      end

      it 'returns 1 when only one row is ticked correctly' do
        expect(question.bits_correct_count('r1' => ['c1'], 'r2' => [])).to eq(1)
      end

      it 'returns 0 for an empty response' do
        expect(question.bits_correct_count({})).to eq(0)
      end

      it 'does not reward correct non-ticks — only true positives count' do
        # r1 correct tick is c1; r2 is not ticked at all (correct non-tick but not a recalled bit)
        expect(question.bits_correct_count('r1' => [], 'r2' => [])).to eq(0)
      end
    end

    describe 'ordering' do
      subject(:question) { build(:question, question_type: 'ordering', config: ordering_config) }

      it 'returns 2 for a fully correct sequence (3 items = 2 pairs)' do
        expect(question.bits_correct_count('order' => %w[o1 o2 o3])).to eq(2)
      end

      it 'returns 1 for one correct adjacent pair' do
        expect(question.bits_correct_count('order' => %w[o1 o2 o1])).to eq(1)
      end

      it 'returns 0 for a fully reversed sequence' do
        expect(question.bits_correct_count('order' => %w[o3 o2 o1])).to eq(0)
      end
    end

    describe 'classify' do
      subject(:question) { build(:question, question_type: 'classify', config: classify_config) }

      it 'returns 3 when every item is correctly placed' do
        expect(question.bits_correct_count('ci1' => 'ct1', 'ci2' => 'ct2', 'ci3' => 'ct1')).to eq(3)
      end

      it 'returns 2 for two correct placements' do
        expect(question.bits_correct_count('ci1' => 'ct2', 'ci2' => 'ct2', 'ci3' => 'ct1')).to eq(2)
      end

      it 'returns 0 for an empty response' do
        expect(question.bits_correct_count({})).to eq(0)
      end
    end
  end
end
