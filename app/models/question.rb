# frozen_string_literal: true

class Question < ApplicationRecord
  has_many :answers, dependent: :destroy
  has_many :asked_questions
  has_many :flagged_questions
  has_many :quizzes, through: :asked_questions
  has_one :question_statistic

  belongs_to :lesson, optional: true
  belongs_to :topic

  has_rich_text :question_text

  enum question_type: %i[short_answer boolean multiple]

  before_update :check_boolean
  before_update :check_short_answer

  accepts_nested_attributes_for :answers, allow_destroy: true

  validates_presence_of :question_text
  validates_associated :answers

  validate :at_least_one_correct_answer
  validate :boolean_true_or_false

  def boolean_true_or_false
    return unless boolean?

    answer_text = answers.pluck(:text)
    # Check for the presence of both true and false in two answers in a case insensitive search
    errors[:base] << 'Boolean question must contain only two answers' unless answer_text.length == 2

    return if answer_text.select { |text| %w[true false].detect { |permitted| permitted.casecmp(text).zero? } }

    errors[:base] << 'Boolean must be true or false only'
  end

  def at_least_one_correct_answer
    errors[:base] << 'Question must have at least one correct answer.' unless answers.each.pluck(:correct).include? true
  end

  private

  def check_boolean
    return unless question_type_changed? && question_type == 'boolean'

    # Setup boolean question.  Only true and false allowed.
    answers.destroy_all
    Answer.create(question: self, correct: false, text: 'False')
    Answer.create(question: self, correct: false, text: 'True')
  end

  def check_short_answer
    return unless question_type_changed? && question_type == 'short_answer'

    # Setup short answer.  Change all answers to correct
    answers.update_all(correct: true)
  end
end
