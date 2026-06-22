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
        increase_student_statistic(q)
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
                               score_sum: calculate_score_sum(question),
                               created_at: now,
                               updated_at: now },
                             unique_by: :question_id)
  end

  # Additive upsert so repeated attempts on the same question accumulate.
  STUDENT_STATISTIC_ON_DUPLICATE = Arel.sql(
    'number_asked = student_question_statistics.number_asked + 1, ' \
    'number_correct = student_question_statistics.number_correct + EXCLUDED.number_correct, ' \
    'score_sum = student_question_statistics.score_sum + EXCLUDED.score_sum, ' \
    'last_asked_at = EXCLUDED.last_asked_at, updated_at = EXCLUDED.updated_at'
  ).freeze

  # Persistent per-student-per-question rollup (survives the asked_question purge below).
  def increase_student_statistic(asked_question)
    now = Time.now
    StudentQuestionStatistic.upsert(
      { user_id: asked_question.quiz.user_id,
        question_id: asked_question.question_id,
        number_asked: 1,
        number_correct: asked_question.correct? ? 1 : 0,
        score_sum: attempt_score(asked_question),
        last_asked_at: now, created_at: now, updated_at: now },
      unique_by: %i[user_id question_id],
      on_duplicate: STUDENT_STATISTIC_ON_DUPLICATE
    )
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

  def calculate_score_sum(asked_question)
    qs = asked_question.question.question_statistic
    (qs.present? ? qs.score_sum : 0.0) + attempt_score(asked_question)
  end

  # Partial-credit score for this attempt. Falls back to correct/incorrect for legacy rows that
  # predate the score column.
  def attempt_score(asked_question)
    return asked_question.score.to_f unless asked_question.score.nil?

    asked_question.correct? ? 1.0 : 0.0
  end
end
