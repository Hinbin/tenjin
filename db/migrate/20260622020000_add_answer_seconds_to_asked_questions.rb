# frozen_string_literal: true

class AddAnswerSecondsToAskedQuestions < ActiveRecord::Migration[8.1]
  def change
    add_column :asked_questions, :answer_seconds, :decimal, precision: 8, scale: 2
  end
end
