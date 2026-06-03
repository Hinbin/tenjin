# frozen_string_literal: true

class UpdateQuestionStatisticsJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    flag_old_quizzes
    update_question_statistics
    clean_old_questions
  end

  def flag_old_quizzes
    Quiz.where('updated_at < ?', 1.day.ago).update_all(active: false)
  end

  def update_question_statistics
    inactive_asked_questions = AskedQuestion.joins(:quiz, :question)
                                            .left_joins(question: :question_statistic)
                                            .where(quizzes: { active: false })
    inactive_asked_questions.each do |q|
      unless q.correct.nil?
        increase_question_asked_count(q)
        increase_question_count_for_user(q)
      end

      q.delete
    end
  end

  def increase_question_asked_count(question)
    correct = calculate_correct(question)
    asked = calculate_asked(question)
    now = Time.now
    QuestionStatistic.upsert({ question_id: question.question_id,
                               number_asked: asked,
                               number_correct: correct,
                               created_at: now,
                               updated_at: now },
                             unique_by: :question_id)
  end

  def increase_question_count_for_user(question)
    UserStatistic.create_or_find_by(
      user: question.quiz.user,
      week_beginning: Date.current.beginning_of_week
    ).increment!(:questions_answered)
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
end
