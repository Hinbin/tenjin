# frozen_string_literal: true

class AskedQuestion < ApplicationRecord
  belongs_to :question
  belongs_to :quiz

  # Anti-cheat: count of answers flagged as answered-too-fast (likely auto-answered) per student, over
  # a recent window so old flags age out. Powers the classroom anomaly column. => { user_id => count }.
  def self.fast_flag_counts(user_ids, since: 14.days.ago)
    where(flagged_fast: true, created_at: since..)
      .joins(:quiz)
      .where(quizzes: { user_id: user_ids })
      .group('quizzes.user_id')
      .count
  end
end
