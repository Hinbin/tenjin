# frozen_string_literal: true

# Engine-shaped import payloads (one per question type Tenjin's import API accepts), matching the
# exact contract the external Question Engine POSTs. Used by the import API request and service specs.
module ImportPayloads
  module_function

  def short_answer(external_id: 1001)
    { external_id:, question_type: 'short_answer', question_text: 'What does RAM stand for?',
      answers: [{ text: 'random access memory', correct: true }] }
  end

  def multiple(external_id: 1002)
    { external_id:, question_type: 'multiple', question_text: 'Which is volatile storage?',
      answers: [{ text: 'RAM', correct: true }, { text: 'SSD', correct: false }] }
  end

  def fill_blank(external_id: 1003)
    { external_id:, question_type: 'fill_blank',
      question_text: 'RAM is {{1}} access {{2}}.', answers: [],
      config: { answer: { '1' => ['random'], '2' => %w[memory store] } } }
  end

  def ordering(external_id: 1004)
    { external_id:, question_type: 'ordering', question_text: 'Order the fetch-execute cycle.',
      answers: [],
      config: { items: [{ id: 'i1', text: 'Fetch' }, { id: 'i2', text: 'Decode' }, { id: 'i3', text: 'Execute' }],
                order: %w[i1 i2 i3] } }
  end

  def matrix(external_id: 1005)
    { external_id:, question_type: 'matrix', question_text: 'Match the component to its job.',
      answers: [],
      config: { rows: [{ id: 'r1', label: 'CPU' }],
                columns: [{ id: 'c1', label: 'Processes data' }, { id: 'c2', label: 'Stores files' }],
                correct: { 'r1' => ['c1'] } } }
  end

  def classify(external_id: 1006)
    { external_id:, question_type: 'classify', question_text: 'Sort the storage by volatility.',
      answers: [],
      config: { items: [{ id: 'i1', text: 'RAM' }, { id: 'i2', text: 'SSD' }],
                targets: [{ id: 't1', label: 'Volatile' }, { id: 't2', label: 'Non-volatile' }],
                correct: { 'i1' => 't1', 'i2' => 't2' } } }
  end

  def drag_drop(external_id: 1007)
    { external_id:, question_type: 'drag_drop', question_text: 'The {{1}} runs the program.',
      answers: [],
      config: { items: [{ id: 'i1', text: 'CPU' }], answer: { '1' => 'i1' } } }
  end

  # One valid payload of every type the engine emits (the six wire types — drag_drop publishes AS a
  # matrix, so it is not part of the engine contract but is included where a native test is wanted).
  def all_engine_types
    [short_answer, multiple, fill_blank, ordering, matrix, classify]
  end
end
