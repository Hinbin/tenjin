# frozen_string_literal: true

class Quiz::CheckAnswer < ApplicationService
  # Anti-cheat floor: a correct answer that arrives sooner than this (seconds since the previous answer
  # / quiz start) is accepted but earns no leaderboard points and is flagged, because no human can read
  # and answer that fast — it's the signature of an auto-answering browser extension. Deliberately
  # conservative so genuinely quick students keep their points. Timing is server-set, so unforgeable.
  MIN_ANSWER_SECONDS = 1.0

  # Question types rendered as something other than clickable answer buttons; everything else is a
  # multiple-choice question (mirrors the `else` branches in check_answer_correct / render_question).
  NON_MULTIPLE_CHOICE_TYPES = %w[short_answer drag_drop matrix fill_blank ordering classify match].freeze

  def initialize(params)
    super()
    @quiz = params[:quiz]
    @question = params[:question]
    @asked_question = AskedQuestion.find_by(quiz: @quiz, question: @question)
    @answer_given = params[:answer_given]
    @points_awarded = 0
  end

  def call
    # Lock in the multiplier the student was shown for THIS question (before answering grows the
    # streak), so the points awarded and the HUD "mult" meter agree — the meter only steps up on the
    # next question, never mid-answer. See Multiplier.for_streak.
    @applied_multiplier = Multiplier.for_streak(@quiz.streak)

    unless already_answered?
      record_timing
      check_answer_correct
    end

    Quiz::MoveQuizForward.call(quiz: @quiz)
    @quiz.save
    reveal_payload
  end

  protected

  # Seconds since the previous answer (or quiz start), stored per answer so speed_run challenges can
  # tell which correct answers were given quickly. Advances the clock for the next question.
  def record_timing
    @answer_seconds = (Time.current - @quiz.time_last_answered).round(2) if @quiz.time_last_answered
    @asked_question.update(answer_seconds: @answer_seconds)
    @quiz.time_last_answered = Time.current
  end

  # Everything the front-end needs to reveal the result: the correct answer(s), the author's optional
  # explanation, plus the running score/streak so the quiz stats and combo juice can update.
  def reveal_payload
    {
      answer: correct_answers_reveal,
      questionType: @question.question_type,
      solution: structured_solution,
      explanation: @question.explanation,
      score: @asked_question.score,
      streak: @quiz.streak,
      answeredCorrect: @quiz.answered_correct,
      multiplier: display_multiplier,
      tooFast: @too_fast.present?
    }.merge(points_payload)
  end

  # Leaderboard points for the HUD: the gain from this answer plus the running quiz total to tick to.
  def points_payload
    { pointsAwarded: @points_awarded, pointsTotal: @quiz.leaderboard_points }
  end

  # The multiplier shown on the "mult" meter — the rate that applied to this answer. Keeping it at the
  # applied rate (rather than jumping to the streak's new tier) is what keeps the meter and the +points
  # pop in agreement; the meter advances to the next tier on the following question's page load.
  def display_multiplier
    @applied_multiplier
  end

  # For multiple choice the reveal carries per-quiz tokens, not the real answer ids (Quiz::AnswerToken),
  # so the reveal itself can't seed a stable answer-id dictionary (#3). Other types reveal by
  # text/solution, so their records are returned unchanged.
  def correct_answers_reveal
    return Quiz::AnswerToken.reveal(@question, quiz_id: @quiz.id) if multiple_choice?

    Answer.where(question: @question, correct: true)
  end

  def multiple_choice?
    NON_MULTIPLE_CHOICE_TYPES.exclude?(@question.question_type)
  end

  def already_answered?
    @asked_question.correct.present?
  end

  def check_answer_correct
    case @question.question_type
    when 'short_answer' then check_short_answer
    when 'drag_drop', 'matrix', 'fill_blank', 'ordering', 'classify', 'match' then check_structured_answer
    else check_multiple_choice
    end
  end

  # Partial-credit types: store the fractional score + raw response (unchanged, feeds difficulty).
  # Points are awarded per bit recalled; a perfect score also increments the streak.
  def check_structured_answer
    response = @answer_given[:structured].to_h
    score = @question.score_response(response)
    bits  = @question.bits_correct_count(response)

    if score >= 1.0
      process_correct_answer(bits: bits)
    elsif bits.positive?
      process_partial_structured_answer(bits: bits)
    else
      process_incorrect_answer
    end
    @asked_question.update(score: score, response: response)
  end

  # The correct mapping for the reveal: drag_drop -> slot=>item; matrix -> row=>[cols];
  # fill_blank -> slot=>accepted text; ordering -> ordered list of item ids; match -> left=>right.
  def structured_solution
    case @question.question_type
    when 'drag_drop', 'fill_blank' then @question.config['answer']
    when 'matrix', 'classify', 'match' then @question.config['correct']
    when 'ordering' then @question.config['order']
    end
  end

  def check_short_answer
    answer_text = Answer.where(question_id: @question).pick(:text)
    return unless answer_text.present?

    if @answer_given[:short_answer].casecmp(answer_text)&.zero?
      process_correct_answer
    else
      process_incorrect_answer
    end
  end

  def check_multiple_choice
    raise 'no valid answer given to multiple choice' if @answer_given[:id].blank?

    # The submitted value is a per-quiz token (Quiz::AnswerToken), not an answer id.
    answer = Quiz::AnswerToken.resolve(@answer_given[:id], @question, quiz_id: @quiz.id)
    return if answer.nil?

    answer.correct ? process_correct_answer : process_incorrect_answer
  end

  def process_correct_answer(bits: 1)
    @quiz.answered_correct += 1
    return flag_too_fast if @answer_seconds.present? && @answer_seconds < MIN_ANSWER_SECONDS

    @quiz.streak += 1
    # Best combo this run — display-only (results screen); does not affect scoring/outcomes.
    @quiz.max_streak = [@quiz.max_streak.to_i, @quiz.streak].max
    @asked_question.update(correct: true, score: 1.0)
    # A clean correct answer earns the multiplier the student was shown for this question.
    award_points(bits, multiplier: @applied_multiplier)
  end

  # Partial credit: student recalled some but not all bits. Streak resets (same penalty as wrong),
  # but points are awarded for the bits they did recall at base multiplier (×1).
  def process_partial_structured_answer(bits:)
    @quiz.streak = 0
    @asked_question.update(correct: false)
    return if @answer_seconds.present? && @answer_seconds < MIN_ANSWER_SECONDS

    award_points(bits, multiplier: 1)
  end

  # Award leaderboard points for this answer and remember the amount so the reveal payload can show
  # the per-question gain and the running quiz total (HUD points tick).
  def award_points(bits, multiplier:)
    @points_awarded = Quiz::AddLeaderboardPoint.call(
      quiz: @quiz, question: @question, answer_seconds: @answer_seconds, bits: bits, multiplier: multiplier
    )
  end

  # Correct, but too fast to be a real read: count it toward the student's own accuracy and let the
  # quiz advance, but award no point and freeze the combo (don't grow OR reset the streak) so the
  # economy can't be farmed. The flag drives the teacher anomaly view (#4); tooFast warns the student.
  def flag_too_fast
    @too_fast = true
    @asked_question.update(correct: true, score: 1.0, flagged_fast: true)
  end

  def process_incorrect_answer
    @quiz.streak = 0
    @asked_question.update(correct: false, score: 0.0)
  end
end
