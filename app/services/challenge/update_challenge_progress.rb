# frozen_string_literal: true

class Challenge::UpdateChallengeProgress < ApplicationService
  def initialize(quiz, number_to_add = 0, question_topic = nil)
    @quiz = quiz
    @number_to_add = number_to_add
    @question_topic = question_topic
  end

  def call
    challenges.find_each do |c|
      @result = check_challenge_progress(c)
      # if updated we'll have a result
      next if @result.blank?

      award_challenge_points?
    end
  end

  protected

  def check_challenge_progress(challenge)
    case challenge.challenge_type
    when 'number_correct' then upsert_progress(@quiz.answered_correct, challenge)
    when 'streak' then upsert_progress(@quiz.streak, challenge)
    when 'number_of_points' then upsert_points(@number_to_add, challenge)
    end
  end

  def award_challenge_points?
    # Check if completed is true and awarded is false
    return unless @result.rows[0][1] == true && @result.rows[0][2] == false

    complete_challenge(ChallengeProgress.find(@result.rows[0][0]))
  end

  def upsert_progress(progress, challenge)
    return unless @quiz.topic == challenge.topic

    completed = progress >= challenge.number_required

    binds = [[nil, progress], [nil, @quiz.user], [nil, challenge.id],
             [nil, challenge.number_required], [nil, completed]]
    ChallengeProgress.connection.exec_query <<~SQL, 'Upsert progress', binds
      INSERT INTO challenge_progresses("progress","user_id", "challenge_id", "completed", "created_at","updated_at")
      values ($1, $2, $3, $5, current_timestamp, current_timestamp)
      ON CONFLICT ("user_id", "challenge_id")
      DO UPDATE
        SET progress =  CASE
                          WHEN challenge_progresses.progress > $4 THEN $1
                          else challenge_progresses.progress
                        END,
            completed  = CASE
                            WHEN challenge_progresses.progress >= $4 OR $1 >= $4
                              OR challenge_progresses.completed = true
                              THEN true
                            ELSE false
                         END
      RETURNING id, completed, awarded
    SQL
  end

  def upsert_points(points, challenge)
    completed = points >= challenge.number_required

    binds = [[nil, points], [nil, @quiz.user], [nil, challenge.id], [nil, completed], [nil, challenge.number_required]]
    ChallengeProgress.connection.exec_query <<~SQL, 'Upsert points', binds
      INSERT INTO challenge_progresses("progress", "user_id", "challenge_id", "completed", "created_at", "updated_at")
      values ($1, $2, $3, $4, current_timestamp, current_timestamp)
      ON CONFLICT ("user_id", "challenge_id")
      DO UPDATE
        SET progress = challenge_progresses.progress + $1,
            completed = CASE
                          WHEN challenge_progresses.progress >= $5
                            OR (challenge_progresses.progress + $1) >= $5
                            OR challenge_progresses.completed = true
                            THEN true
                          ELSE false
                        END
      RETURNING id, completed, awarded
    SQL
  end

  def challenges
    Challenge.joins(:topic)
             .includes(topic: :subject)
             .where(topics: { subject_id: @quiz.subject })
             .where('end_date > ?', Time.current)
  end

  def check_number_correct(challenge)
    return 0 unless @quiz.topic == challenge.topic

    @quiz.answered_correct
  end

  def check_streak(challenge)
    return 0 unless @quiz.topic == challenge.topic

    @quiz.streak
  end

  def check_number_of_points(challenge, challenge_points)
    unless @question_topic == challenge.topic || (challenge.daily && @question_topic.subject == challenge.topic.subject)
      return 0
    end

    challenge_points.progress + @number_to_add
  end

  def complete_challenge(progress)
    progress.awarded = true

    progress.user.challenge_points = 0 if progress.user.challenge_points.nil?
    progress.user.challenge_points += progress.challenge.points
    progress.user.save
  end
end
