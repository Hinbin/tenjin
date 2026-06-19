# frozen_string_literal: true

class Quiz < ApplicationRecord
  belongs_to :user
  belongs_to :subject
  belongs_to :topic, optional: true
  belongs_to :lesson, optional: true

  has_many :asked_questions
  has_many :questions, through: :asked_questions
  attr_accessor :topic_id, :picked_subject

  # XP awarded per correct answer (progression display only — never affects scoring/leaderboard).
  POINTS_PER_CORRECT = 10

  def total_questions
    questions.length
  end

  # End-of-quiz accuracy as a whole-number percentage (0 when nothing was asked).
  def accuracy_percent
    return 0 if total_questions.zero?

    ((answered_correct.to_i / total_questions.to_f) * 100).round
  end

  # Progression XP earned by this quiz. Deterministic from final state, so recording is idempotent.
  def points_earned
    answered_correct.to_i * POINTS_PER_CORRECT
  end
end
