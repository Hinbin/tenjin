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

    ChallengeProgress.upsert_all([
      { progress: progress, user_id: @quiz.user.id, challenge_id: challenge.id, completed: }
    ],
                                 unique_by: %w[user_id challenge_id],
                                 on_duplicate: Arel.sql("progress =  CASE
                                  WHEN challenge_progresses.progress > #{challenge.number_required} THEN #{progress}
                                  else challenge_progresses.progress
                                END,
                                completed  = CASE
                                    WHEN challenge_progresses.progress >= #{challenge.number_required} OR #{progress} >= #{challenge.number_required}
                                      OR challenge_progresses.completed = true
                                      THEN true
                                    ELSE false
                                 END"),
                                 returning: %w[id completed awarded])
  end

  def upsert_points(points, challenge)
    unless challenge.topic == @quiz.topic ||
           challenge.topic == @question_topic ||
           (challenge.daily && challenge.topic.subject == @question_topic.subject)
      return
    end

    completed = points >= challenge.number_required

    ChallengeProgress.upsert_all([
      { progress: points, user_id: @quiz.user.id, challenge_id: challenge.id, completed: }
    ],
                                 unique_by: %w[user_id challenge_id],
                                 on_duplicate: Arel.sql("progress = challenge_progresses.progress + #{points},
                                  completed = CASE
                                                WHEN challenge_progresses.progress >= #{challenge.number_required}
                                                  OR (challenge_progresses.progress + #{points}) >= #{challenge.number_required}
                                                  OR challenge_progresses.completed = true
                                                  THEN true
                                                ELSE false
                                              END"),
                                 returning: %w[id completed awarded])
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

  def complete_challenge(progress)
    progress.awarded = true
    progress.save

    progress.user.challenge_points = 0 if progress.user.challenge_points.nil?
    progress.user.challenge_points += progress.challenge.points
    progress.user.save
  end
end
