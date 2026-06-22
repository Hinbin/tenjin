# frozen_string_literal: true

# Anti-cheat: turns a multiple-choice answer's database id into a per-quiz opaque token used as the
# DOM/button id and the submitted value, instead of exposing the stable `answers.id`. Because the
# token mixes in the quiz id, the same answer gets a different token in every quiz, so a browser
# extension can't build a durable "question -> correct answer id" dictionary and replay it.
#
# Stateless: the token is an HMAC of (quiz_id : question_id : answer_id) keyed on the app secret, so
# nothing is stored. To resolve a submitted token back to an answer we recompute the token for each
# of the question's answers (a handful) and match — see Quiz::CheckAnswer#resolve_answer_token.
module Quiz::AnswerToken
  module_function

  TOKEN_LENGTH = 32

  def for(quiz_id:, question_id:, answer_id:)
    data = [quiz_id, question_id, answer_id].join(':')
    OpenSSL::HMAC.hexdigest('SHA256', secret, data)[0, TOKEN_LENGTH]
  end

  # True when `token` is the token for `answer_id` within this quiz/question. Constant-time compare so
  # the lookup can't be probed by timing.
  def valid?(token, quiz_id:, question_id:, answer_id:)
    return false if token.blank?

    expected = self.for(quiz_id: quiz_id, question_id: question_id, answer_id: answer_id)
    ActiveSupport::SecurityUtils.secure_compare(token.to_s, expected)
  end

  # The answer in `question` whose token matches `token` for this quiz, or nil for a tampered/stale one.
  def resolve(token, question, quiz_id:)
    question.answers.find do |answer|
      valid?(token, quiz_id: quiz_id, question_id: question.id, answer_id: answer.id)
    end
  end

  # The correct answers for a multiple-choice reveal, exposing only the per-quiz token + text — never
  # the real answer id, which would let the reveal itself seed a stable answer-id dictionary.
  def reveal(question, quiz_id:)
    question.answers.select(&:correct).map do |answer|
      { token: self.for(quiz_id: quiz_id, question_id: question.id, answer_id: answer.id), text: answer.text }
    end
  end

  def secret
    Rails.application.secret_key_base
  end
end
