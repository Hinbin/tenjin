# frozen_string_literal: true

class AddQuizStartIndexes < ActiveRecord::Migration[7.0]
  def change
    add_index :questions, %i[topic_id active], name: 'index_questions_on_topic_id_and_active'
    add_index :questions, %i[lesson_id active], name: 'index_questions_on_lesson_id_and_active'
    add_index :topics, %i[subject_id active], name: 'index_topics_on_subject_id_and_active'
    add_index :usage_statistics, %i[user_id topic_id lesson_id date],
              name: 'index_usage_statistics_on_quiz_start_lookup'
  end
end
