# frozen_string_literal: true

class Quiz::CheckAnswer < ApplicationService
  def initialize(params)
    super()
    @quiz = params[:quiz]
    @question = params[:question]
    @asked_question = AskedQuestion.find_by(quiz: @quiz, question: @question)
    @answer_given = params[:answer_given]
  end

  def call
    check_answer_correct unless already_answered?

    Quiz::MoveQuizForward.call(quiz: @quiz)
    @quiz.save
    {
      answer: Answer.where(question: @question, correct: true),
      questionType: @question.question_type,
      solution: structured_solution,
      score: @asked_question.score,
      streak: @quiz.streak,
      answeredCorrect: @quiz.answered_correct,
      multiplier: Multiplier.where('score <= ?', @quiz.streak).order(id: :desc).pick(:multiplier)
    }
  end

  protected

  def already_answered?
    @asked_question.correct.present?
  end

  def check_answer_correct
    case @question.question_type
    when 'short_answer' then check_short_answer
    when 'drag_drop', 'matrix' then check_structured_answer
    else check_multiple_choice
    end
  end

  # Partial-credit types: store the fractional score + raw response; a perfect score counts as
  # correct for streak/leaderboard, anything less resets the streak like a wrong answer.
  def check_structured_answer
    response = @answer_given[:structured].to_h
    score = @question.score_response(response)

    score >= 1.0 ? process_correct_answer : process_incorrect_answer
    @asked_question.update(score: score, response: response)
  end

  # The correct mapping for the reveal: drag_drop -> slot=>item; matrix -> row=>[cols].
  def structured_solution
    case @question.question_type
    when 'drag_drop' then @question.config['answer']
    when 'matrix' then @question.config['correct']
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

    answer = Answer.where(id: @answer_given[:id]).pick(:correct)
    return unless answer.present?

    if answer
      process_correct_answer
    else
      process_incorrect_answer
    end
  end

  def process_correct_answer
    @quiz.answered_correct += 1
    @quiz.streak += 1
    # Best combo this run — display-only (results screen); does not affect scoring/outcomes.
    @quiz.max_streak = [@quiz.max_streak.to_i, @quiz.streak].max
    @asked_question.update(correct: true, score: 1.0)
    Quiz::AddLeaderboardPoint.call(quiz: @quiz, question: @question)
  end

  def process_incorrect_answer
    @quiz.streak = 0
    @asked_question.update(correct: false, score: 0.0)
  end
end
