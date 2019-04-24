class Question < ApplicationRecord
  has_many :answers
  has_many :asked_questions
  has_many :quizzes, through: :asked_questions
  belongs_to :topic

  has_rich_text :question_text

  enum question_type: %i[short_answer boolean multiple]

  before_update :check_boolean
  before_update :check_short_answer

  before_destroy :destroy_answers

  def self.clean_empty_questions(topic)
    questions = Question.where(topic_id: topic).includes(:answers, :asked_questions)
    update_questions = false
    # Clean up empty questions
    questions.each do |q|
      next unless q.question_text.blank?

      q.answers.destroy_all
      q.destroy
      update_questions = true
    end

    update_questions ? Question.where(topic_id: topic).includes(:answers, :asked_questions) : questions
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

  def destroy_answers
    answers.destroy_all
  end
end
