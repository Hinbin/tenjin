# frozen_string_literal: true

class Question < ApplicationRecord
  include StructuredQuestion

  has_many :answers, dependent: :destroy
  has_many :asked_questions, dependent: :destroy
  has_many :flagged_questions, dependent: :destroy
  has_many :quizzes, through: :asked_questions
  has_many :student_question_statistics, dependent: :destroy
  has_one :question_statistic, dependent: :destroy

  belongs_to :lesson, optional: true, counter_cache: true
  belongs_to :topic

  has_rich_text :question_text

  # NOTE: integer 1 (formerly :boolean) is intentionally retired and left unused — boolean questions
  # were migrated to :multiple (they were already two-answer True/False MCQs).
  enum :question_type, { short_answer: 0, multiple: 2, drag_drop: 3, matrix: 4,
                         fill_blank: 5, ordering: 6 }

  before_update :check_short_answer

  accepts_nested_attributes_for :answers, allow_destroy: true

  validates :question_text, presence: true
  validates_associated :answers

  validate :at_least_one_correct_answer
  validate :lesson_is_for_topic

  def lesson_is_for_topic
    errors.add(:base, 'Lesson topic must match question topic') unless lesson.blank? || lesson.topic == topic
  end

  def at_least_one_correct_answer
    return unless answer_based?
    return if answers.each.pluck(:correct).include? true

    errors.add(:base, 'Question must have at least one correct answer.')
  end

  def as_json(*)
    json = { question_text: question_text.body,
             question_type:,
             answers: answers.as_json(only: %i[text correct]) }
    json[:explanation] = explanation if explanation.present?
    json[:lesson] = lesson.title if lesson
    json[:config] = config if structured?
    json
  end

  private

  def check_short_answer
    return unless question_type_changed? && question_type == 'short_answer'

    # Setup short answer.  Change all answers to correct
    answers.update_all(correct: true)
  end

  def plain_question_text
    question_text.to_plain_text
  end
end
