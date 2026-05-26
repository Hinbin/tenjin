# frozen_string_literal: true

class Question < ApplicationRecord
  has_many :answers, dependent: :destroy
  has_many :asked_questions, dependent: :destroy
  has_many :flagged_questions, dependent: :destroy
  has_many :quizzes, through: :asked_questions
  has_one :question_statistic, dependent: :destroy

  belongs_to :lesson, optional: true, counter_cache: true
  belongs_to :topic

  has_rich_text :question_text

  enum question_type: {short_answer: 0, boolean: 1, multiple: 2}

  before_update :check_boolean
  before_update :check_short_answer

  accepts_nested_attributes_for :answers, allow_destroy: true

  validates :question_text, presence: true
  validates_associated :answers

  validate :at_least_one_correct_answer
  validate :boolean_true_or_false
  validate :lesson_is_for_topic

  def lesson_is_for_topic
    errors.add :base, "Lesson topic must match question topic" unless lesson.blank? || lesson.topic == topic
  end

  def boolean_true_or_false
    return unless boolean?

    answer_text = answers.filter_map { |i| i&.text }
    # Check for the presence of both true and false in two answers in a case insensitive search
    return errors.add :base, "Boolean question must contain two answers" unless answer_text.size == 2

    return if answer_text.all? { |text| %w[true false].any? { |permitted| permitted.casecmp(text).zero? } }

    errors.add :base, "Boolean must be true or false only"
  end

  def at_least_one_correct_answer
    return if answers.any?(&:correct)

    errors.add :base, "Question must have at least one correct answer."
  end

  def as_json(*)
    json = {question_text: question_text.body,
            question_type: question_type,
            answers: answers.as_json(only: %i[text correct])}
    json[:lesson] = lesson.title if lesson
    json
  end

  private

  def check_boolean
    return unless question_type_changed? && boolean?

    answers.destroy_all
    Answer.create(question: self, correct: false, text: "False")
    Answer.create(question: self, correct: false, text: "True")
  end

  def check_short_answer
    return unless question_type_changed? && short_answer?

    answers.update_all(correct: true)
  end

  def plain_question_text
    question_text.to_plain_text
  end
end
