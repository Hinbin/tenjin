# frozen_string_literal: true

namespace :maintainence do
  desc 'Update counts'
  task convert_boolean_questions: :environment do
    Question.all.where(question_type: :boolean).each do |q|
      # find which answer is true or false
      correct_id = q.answers.where(correct: true)
      true_is_correct = Answer.where('question_id = ? AND UPPER(text) LIKE TRUE').correct
      false_is_correct = Answer.where('question_id = ? AND UPPER(text) LIKE %false%').correct

    end

  end
end
