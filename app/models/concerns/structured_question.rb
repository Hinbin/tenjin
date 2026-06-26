# frozen_string_literal: true

# StructuredQuestion — the richer, harder question types whose content lives in `questions.config`
# rather than the flat `answers` table.
#
#   drag_drop: the question_text is the cloze sentence with {{n}} blanks; students drag item tiles
#     into the blanks. config = { "items" => [{ "id" =>, "text" => }], "answer" => { "1" => item_id, … } }
#     A blank may accept more than one item — its answer is then an array of item ids ("1" => [a, b]);
#     a single id is still accepted for back-compatibility.
#   matrix:    rows × columns of tick boxes; each row has one or more correct columns.
#     config = { "rows" => [{ "id" =>, "label" => }], "columns" => [{ "id" =>, "label" => }],
#                "correct" => { row_id => [col_id, …] } }
#   fill_blank: like drag_drop the question_text is the cloze with {{n}} blanks, but students TYPE the
#     answer rather than dragging a tile — retrieval practice, not recognition. Each blank stores one
#     or more accepted strings; alternatives are separated with "|" ("RAM|random access memory").
#     config = { "answer" => { "1" => "control|control unit", "2" => "arithmetic logic" } }
#   ordering:  students arrange shuffled item tiles into the correct sequence (a process: sort steps,
#     fetch-decode-execute, …). config = { "items" => [{ "id" =>, "text" => }], "order" => [id, …] }
#
# Scoring is partial-credit (0.0..1.0) so difficulty analysis can tell a near-miss from a blank.
module StructuredQuestion
  extend ActiveSupport::Concern

  STRUCTURED_TYPES = %w[drag_drop matrix fill_blank ordering classify].freeze
  ANSWER_BASED_TYPES = %w[short_answer multiple].freeze
  SLOT_PATTERN = /\{\{(\w+)\}\}/

  included do
    validate :drag_drop_config_valid
    validate :matrix_config_valid
    validate :fill_blank_config_valid
    validate :ordering_config_valid
    validate :classify_config_valid
  end

  def structured?
    STRUCTURED_TYPES.include?(question_type)
  end

  def answer_based?
    ANSWER_BASED_TYPES.include?(question_type)
  end

  # Partial-credit score (0.0..1.0) for a student's response to a structured question.
  def score_response(response)
    case question_type
    when 'drag_drop' then score_drag_drop(normalize_response(response))
    when 'matrix' then score_matrix(normalize_response(response))
    when 'fill_blank' then score_fill_blank(normalize_response(response))
    when 'ordering' then score_ordering(normalize_response(response))
    when 'classify' then score_classify(normalize_response(response))
    else 0.0
    end
  end

  # Integer count of correctly recalled "bits" for leaderboard point awards.
  # Intentionally separate from score_response (which stays 0-1 for difficulty analytics).
  def bits_correct_count(response)
    norm = normalize_response(response)
    case question_type
    when 'drag_drop'  then drag_drop_bits(norm)
    when 'fill_blank' then fill_blank_bits(norm)
    when 'matrix'     then matrix_bits(norm)
    when 'ordering'   then ordering_bits(norm)
    when 'classify'   then classify_bits(norm)
    else 0
    end
  end

  # Ordered list of blank identifiers parsed from the question text (drag_drop only). The cloze
  # sentence IS the question text — authors mark blanks inline with {{1}}, {{2}}, …
  def config_slots
    cloze_text.scan(SLOT_PATTERN).flatten
  end

  # The plain-text question used as the drag_drop cloze.
  def cloze_text
    question_text.to_plain_text.to_s
  rescue StandardError
    ''
  end

  private

  def normalize_response(response)
    return {} if response.blank?

    hash = response.respond_to?(:to_unsafe_h) ? response.to_unsafe_h : response
    hash.to_h.stringify_keys
  end

  def score_drag_drop(response)
    score_answer_slots(response) { |given, accepted| Array(accepted).include?(given) }
  end

  # Shared by the slot-keyed types (drag_drop, fill_blank): config['answer'] maps each blank to its
  # expected value; reward each blank whose response satisfies the block. Partial credit = mean.
  def score_answer_slots(response)
    answer = config['answer'].to_h
    return 0.0 if answer.empty?

    correct = answer.count { |slot, expected| yield(response[slot.to_s], expected) }
    correct.to_f / answer.size
  end

  def score_matrix(response)
    rows = config['rows'].to_a
    columns = config['columns'].to_a
    return 0.0 if rows.empty? || columns.empty?

    rows.sum { |row| matrix_row_score(row['id'], columns, response) } / rows.size
  end

  # Per row, every column is a true/false decision; reward each cell that matches the key. Mean
  # across the row's columns, so over-ticking is penalised and partial selections score partially.
  def matrix_row_score(row_id, columns, response)
    expected = config.dig('correct', row_id).to_a
    selected = response[row_id].to_a
    hits = columns.count { |col| expected.include?(col['id']) == selected.include?(col['id']) }
    hits.to_f / columns.size
  end

  def drag_drop_config_valid
    return unless question_type == 'drag_drop'

    errors.add(:base, 'Drag-and-drop needs at least one {{n}} blank') if config_slots.empty?
    errors.add(:base, 'Every blank needs a correct item') unless all_slots_answered?
    errors.add(:base, 'Answers must reference existing items') unless drag_drop_answers_exist?
  end

  def all_slots_answered?
    config_slots.all? { |slot| config.dig('answer', slot).present? }
  end

  def drag_drop_answers_exist?
    item_ids = config['items'].to_a.filter_map { |item| item['id'] }
    config['answer'].to_h.values.flatten.all? { |id| item_ids.include?(id) }
  end

  def matrix_config_valid
    return unless question_type == 'matrix'

    errors.add(:base, 'Matrix needs at least one row') if config['rows'].to_a.empty?
    errors.add(:base, 'Matrix needs at least one column') if config['columns'].to_a.empty?
    errors.add(:base, 'Each row needs at least one correct answer') unless matrix_every_row_correct?
  end

  def matrix_every_row_correct?
    rows = config['rows'].to_a
    rows.any? && rows.all? { |row| config.dig('correct', row['id']).to_a.any? }
  end

  # ---- fill_blank -----------------------------------------------------------
  # Each blank is one typed answer; reward each blank whose typed text matches an accepted answer.
  def score_fill_blank(response)
    score_answer_slots(response) { |given, accepted| fill_blank_match?(given, accepted) }
  end

  # Lenient match: trimmed and case-insensitive, against any of the "|"-separated alternatives.
  def fill_blank_match?(given, accepted)
    given = given.to_s.strip
    return false if given.empty?

    acceptable_answers(accepted).any? { |candidate| candidate.casecmp?(given) }
  end

  def acceptable_answers(accepted)
    list = accepted.is_a?(Array) ? accepted : accepted.to_s.split('|')
    list.map { |candidate| candidate.to_s.strip }.reject(&:empty?)
  end

  def fill_blank_config_valid
    return unless question_type == 'fill_blank'

    errors.add(:base, 'Gap-fill needs at least one {{n}} blank') if config_slots.empty?
    errors.add(:base, 'Every blank needs an accepted answer') unless fill_blank_all_answered?
  end

  def fill_blank_all_answered?
    config_slots.all? { |slot| acceptable_answers(config.dig('answer', slot)).any? }
  end

  # ---- ordering -------------------------------------------------------------
  # Adjacency scoring: reward each correct consecutive PAIR rather than absolute position, so credit
  # reflects how much of the sequence is in the right relative order. A fully reversed list scores 0
  # (no adjacent pair survives), and there's no "middle item stays put" artefact of position scoring.
  # config['order'] is the key sequence; the response carries the student's sequence under 'order'.
  def score_ordering(response)
    order = config['order'].to_a
    return 0.0 if order.size < 2

    given = response['order'].to_a
    correct = order.each_cons(2).count { |first, second| adjacent_in?(given, first, second) }
    correct.to_f / (order.size - 1)
  end

  # True when `second` immediately follows `first` in the student's sequence.
  def adjacent_in?(sequence, first, second)
    index = sequence.index(first)
    !index.nil? && sequence[index + 1] == second
  end

  def ordering_config_valid
    return unless question_type == 'ordering'

    errors.add(:base, 'Ordering needs at least two items') if config['items'].to_a.size < 2
    errors.add(:base, 'Ordering needs a complete correct sequence') unless ordering_sequence_valid?
  end

  # The correct order must list every item exactly once.
  def ordering_sequence_valid?
    item_ids = config['items'].to_a.filter_map { |item| item['id'] }
    order = config['order'].to_a
    item_ids.size >= 2 && order.sort == item_ids.sort
  end

  # ---- classify ----------------------------------------------------------------
  # Students assign each item tile to one of several named target buckets.
  # config = { "items" => [{ "id" =>, "text" => }], "targets" => [{ "id" =>, "label" => }],
  #            "correct" => { item_id => target_id, … } }
  # Response = { item_id => target_id } for each item the student placed.
  # Partial-credit: mean across all items (unplaced items score 0).
  def score_classify(response)
    correct_map = config['correct'].to_h
    item_ids = config['items'].to_a.filter_map { |item| item['id'] }
    return 0.0 if item_ids.empty?

    correct = item_ids.count { |id| response[id] == correct_map[id] }
    correct.to_f / item_ids.size
  end

  def classify_config_valid
    return unless question_type == 'classify'

    errors.add(:base, 'Classify needs at least two items')   if config['items'].to_a.size < 2
    errors.add(:base, 'Classify needs at least two targets') if config['targets'].to_a.size < 2
    errors.add(:base, 'Every item needs a correct target')   unless classify_all_items_assigned?
    errors.add(:base, 'Targets must reference existing targets') unless classify_targets_exist?
  end

  def classify_all_items_assigned?
    config['items'].to_a.filter_map { |item| item['id'] }.all? { |id| config.dig('correct', id).present? }
  end

  def classify_targets_exist?
    target_ids = config['targets'].to_a.filter_map { |t| t['id'] }
    config['correct'].to_h.values.all? { |id| target_ids.include?(id) }
  end

  # ---- bits_correct helpers -------------------------------------------------

  def drag_drop_bits(response)
    answer = config['answer'].to_h
    answer.count { |slot, expected| Array(expected).include?(response[slot.to_s]) }
  end

  def fill_blank_bits(response)
    answer = config['answer'].to_h
    answer.count { |slot, expected| fill_blank_match?(response[slot.to_s], expected) }
  end

  # Counts true positives only: cells the key marks as ticked that the student also ticked.
  # Correct non-ticks are not counted as recalled bits (they're a default, not recalled knowledge).
  def matrix_bits(response)
    config['rows'].to_a.sum do |row|
      row_id = row['id']
      expected = config.dig('correct', row_id).to_a
      selected = response[row_id].to_a
      expected.count { |col_id| selected.include?(col_id) }
    end
  end

  def ordering_bits(response)
    order = config['order'].to_a
    return 0 if order.size < 2

    given = response['order'].to_a
    order.each_cons(2).count { |first, second| adjacent_in?(given, first, second) }
  end

  def classify_bits(response)
    correct_map = config['correct'].to_h
    item_ids = config['items'].to_a.filter_map { |item| item['id'] }
    item_ids.count { |id| response[id] == correct_map[id] }
  end
end
