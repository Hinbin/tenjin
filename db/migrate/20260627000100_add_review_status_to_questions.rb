# frozen_string_literal: true

class AddReviewStatusToQuestions < ActiveRecord::Migration[8.1]
  def change
    add_column :questions, :review_status, :integer, default: 0, null: false
  end
end
