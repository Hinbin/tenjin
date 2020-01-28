# frozen_string_literal: true

class UpdateQuestionStatisticsJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    update_question_statistics
    update_flagged_questions
    clean_old_questions
  end

  def update_question_statistics
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

      UsageStatistic.find_by(user: q.quiz.user_id).increment!(:questions_answered)

      q.delete
    end
  end

  def clean_old_questions
    AskedQuestion.joins(:quiz, :question)
                 .left_joins(question: :question_statistic)
                 .where(quizzes: { active: false })
                 .destroy_all

    AskedQuestion.where('updated_at < ?', 1.day.ago)
                 .destroy_all
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

  def update_flagged_questions
    Question.find_each do |q|
      Question.reset_counters(q.id, :flagged_questions)
    end
  end
end
