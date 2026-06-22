# frozen_string_literal: true

class AddScoringColumns < ActiveRecord::Migration[8.1]
  def up
    # Partial-credit score (0..1) for a single attempt, plus the raw student response so richer
    # question types (drag-and-drop, matrix) can be re-scored / inspected. nil = legacy / unscored.
    add_column :asked_questions, :score, :decimal, precision: 5, scale: 4
    add_column :asked_questions, :response, :jsonb

    # Running sum of partial-credit scores so difficulty can use mean score, not just correct count.
    add_column :question_statistics, :score_sum, :float, default: 0.0, null: false

    # Seed score_sum from the existing correct counts so difficulty has data on day one.
    execute('UPDATE question_statistics SET score_sum = number_correct WHERE number_correct IS NOT NULL')
  end

  def down
    remove_column :question_statistics, :score_sum
    remove_column :asked_questions, :response
    remove_column :asked_questions, :score
  end
end
