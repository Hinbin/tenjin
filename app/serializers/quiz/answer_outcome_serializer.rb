# frozen_string_literal: true

class Quiz::AnswerOutcomeSerializer
  def initialize(outcome)
    @outcome = outcome
  end

  def as_json(*)
    {
      answer: Answer.where(question: @outcome.question, correct: true),
      streak: @outcome.streak,
      answeredCorrect: @outcome.answered_correct,
      multiplier: @outcome.multiplier
    }
  end
end
