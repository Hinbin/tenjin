# frozen_string_literal: true

# StructuredQuestion — the richer, harder question types whose content lives in `questions.config`
# rather than the flat `answers` table.
#
#   drag_drop: cloze text with {{n}} blanks; students drag item tiles into the blanks.
#     config = { "text" => "… {{1}} …", "items" => [{ "id" =>, "text" => }],
#                "answer" => { "1" => item_id, … } }
#   matrix:    rows × columns of tick boxes; each row has one or more correct columns.
#     config = { "rows" => [{ "id" =>, "label" => }], "columns" => [{ "id" =>, "label" => }],
#                "correct" => { row_id => [col_id, …] } }
#
# Scoring is partial-credit (0.0..1.0) so difficulty analysis can tell a near-miss from a blank.
module StructuredQuestion
  extend ActiveSupport::Concern

  STRUCTURED_TYPES = %w[drag_drop matrix].freeze
  ANSWER_BASED_TYPES = %w[short_answer boolean multiple].freeze
  SLOT_PATTERN = /\{\{(\w+)\}\}/

  included do
    validate :drag_drop_config_valid
    validate :matrix_config_valid
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
    else 0.0
    end
  end

  # Ordered list of blank identifiers parsed from the cloze text (drag_drop only).
  def config_slots
    config['text'].to_s.scan(SLOT_PATTERN).flatten
  end

  private

  def normalize_response(response)
    return {} if response.blank?

    hash = response.respond_to?(:to_unsafe_h) ? response.to_unsafe_h : response
    hash.to_h.stringify_keys
  end

  def score_drag_drop(response)
    answer = config['answer'].to_h
    return 0.0 if answer.empty?

    correct = answer.count { |slot, item_id| response[slot.to_s] == item_id }
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
    config['answer'].to_h.values.all? { |id| item_ids.include?(id) }
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
end
