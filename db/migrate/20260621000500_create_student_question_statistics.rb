# frozen_string_literal: true

class CreateStudentQuestionStatistics < ActiveRecord::Migration[8.1]
  def change
    # Persistent per-student-per-question rollup. asked_questions are purged daily by
    # UpdateQuestionStatisticsJob, so this table is the durable record that powers per-student
    # gap analysis (how a student does on specific questions, difficulty-weighted vs the cohort).
    create_table :student_question_statistics do |t|
      t.references :user, null: false, foreign_key: true
      t.references :question, null: false, foreign_key: true
      t.integer :number_asked, default: 0, null: false
      t.integer :number_correct, default: 0, null: false
      t.float :score_sum, default: 0.0, null: false
      t.datetime :last_asked_at

      t.timestamps
    end

    add_index :student_question_statistics, %i[user_id question_id], unique: true
  end
end
