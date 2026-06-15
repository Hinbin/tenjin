# frozen_string_literal: true

# Plain value object carrying the result of checking a single quiz answer.
# Created by Quiz::CheckAnswer, consumed by Quiz::AnswerOutcomeSerializer.
Quiz::CheckAnswerOutcome = Data.define(:question, :streak, :answered_correct, :multiplier)
