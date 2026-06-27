# frozen_string_literal: true

# The original review_status column defaulted to :pending (0), which (a) stamped every
# pre-existing question as pending so the review queue swept up the whole question bank,
# and (b) would route normally-created questions through review too. Only API-imported
# questions (Question::ImportApiQuestions) should arrive pending; they are also inactive.
# No real API imports exist yet, so every pre-existing question is spurious-pending: backfill
# them all (active and inactive) to approved and flip the default so normal creation stays live.
class FixQuestionReviewStatusDefaults < ActiveRecord::Migration[8.1]
  def up
    change_column_default :questions, :review_status, from: 0, to: 1

    approved = Question.review_statuses[:approved]
    Question.where.not(review_status: approved).update_all(review_status: approved)
  end

  def down
    change_column_default :questions, :review_status, from: 1, to: 0
  end
end
