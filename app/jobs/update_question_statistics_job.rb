# frozen_string_literal: true

class UpdateQuestionStatisticsJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    inactive_asked_questions = AskedQuestion.joins(:quiz, :question)
                                            .left_joins(question: :question_statistic)
                                            .where(quizzes: { active: false })
    inactive_asked_questions.each do |q|
      next if q.correct.nil?

      correct = calculate_correct(q)
      asked = calculate_asked(q)
      now = Time.now
      QuestionStatistic.upsert({ question_id: q.question_id,
                                 number_asked: asked,
                                 number_correct: correct,
                                 created_at: now,
                                 updated_at: now },
                               unique_by: :question_id)
      q.delete
    end
  end

  def calculate_correct(asked_question)
    qs = asked_question.question.question_statistic

    if asked_question.correct?
      qs.present? ? qs.number_correct + 1 : 1
    else
      qs.present? ? qs.number_correct : 0
    end
  end

  def calculate_asked(asked_question)
    return 1 unless asked_question.question.question_statistic.present?

    asked_question.question.question_statistic.number_asked + 1
  end
end
