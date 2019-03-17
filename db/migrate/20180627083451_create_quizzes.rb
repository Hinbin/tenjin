# frozen_string_literal: true

class CreateQuizzes < ActiveRecord::Migration[5.2]
  def change
    create_table :quizzes do |t|
      t.datetime :time_last_answered
      t.integer :streak
      t.integer :answered_correct
      t.integer :num_questions_asked
      t.references :user, foreign_key: true
      t.references :subject, foreign_Key: true
      t.references :topic, foreign_key: true
      t.boolean :active

      t.timestamps
    end
  end
end
