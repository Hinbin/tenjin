# frozen_string_literal: true

class CreateQuizzes < ActiveRecord::Migration[5.2]
  def change
    create_table :quizzes do |t|
      t.references :questions_asked, array: true, default: []
      t.datetime :date_started
      t.datetime :time_last_updated
      t.integer :streak
      t.integer :answered_correct
      t.integer :num_questions_asked
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end
