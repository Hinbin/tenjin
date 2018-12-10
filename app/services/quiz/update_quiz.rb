# Takes a quiz, checks an incoming answer is correct and then
# updates to the next question.  Increments streak and answered correct counters
# Finally, checks to see if the quiz has finished and destroys as necessary.
class Quiz::UpdateQuiz
  def initialize(params)
    @quiz = params[:quiz]
    @question = params[:question]
    @answer_given = params[:answer_given]
    @user = params[:user]
    @asked_question = @question.asked_questions.first
  end

  def call
    check_answer_correct
    move_to_next_question
    check_if_quiz_finished
    self
  end

  private

  def check_answer_correct
    if @question.answers_count == 1
      check_short_answer
    else
      check_multiple_choice
    end

    @asked_question.save
    @question.save
  end

  def move_to_next_question
    @quiz.num_questions_asked = @quiz.num_questions_asked + 1
    @quiz.save
  end

  def check_if_quiz_finished
    return unless @quiz.num_questions_asked >= @quiz.questions.length

    @quiz.active = false
    @quiz.save
  end

  def process_correct_answer
    @quiz.answered_correct += 1
    @quiz.streak += 1
    @asked_question.correct = true
    add_to_leaderboard
    broadcast_leaderboard_point
  end

  def process_incorrect_answer
    @quiz.streak = 0
    @asked_question.correct = false
  end

  def add_to_leaderboard
    @topic_score = @user.topic_scores.where(topic: @question.topic).first_or_initialize
    @topic_score.score = 0 if @topic_score.new_record?
    @topic_score.score += 1
    @topic_score.save
  end

  def broadcast_leaderboard_point
    subject = @quiz.subject
    channel_name = subject.name, @user.school.name
    subject_score = TopicScore.joins(:subject).where('user_id = ? AND subject_id = ?', @user.id, subject.id).group(:subject_id).sum(:score)[1]
    message = { user: @user.forename, topic_score: @topic_score.score, subject_score: subject_score }
    LeaderboardChannel.broadcast_to(channel_name, message)
  end

  def check_short_answer
    @correct_answer = @question.answers.first.text
    if @answer_given.casecmp(@correct_answer).zero?
      process_correct_answer
    else
      process_incorrect_answer
    end
  end

  def check_multiple_choice
    @answer = Answer.find_by(id: @answer_given)
    if @answer.correct
      process_correct_answer
    else
      process_incorrect_answer
    end
  end
end
