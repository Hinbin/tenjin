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
    when "number_correct" then upsert_progress(@quiz.answered_correct, challenge)
    when "streak" then upsert_progress(@quiz.streak, challenge)
    when "number_of_points" then upsert_points(@number_to_add, challenge)
    end
  end

  def award_challenge_points?
    id, completed, awarded = @result.rows[0]
    return unless completed == true && awarded == false

    complete_challenge(ChallengeProgress.find(id))
  end

  def upsert_progress(progress, challenge)
    return unless @quiz.topic == challenge.topic

    completed = progress >= challenge.number_required
    required = challenge.number_required.to_i

    ChallengeProgress.upsert_all(
      [{progress: progress, user_id: @quiz.user_id, challenge_id: challenge.id, completed: completed}],
      unique_by: %i[user_id challenge_id],
      on_duplicate: Arel.sql(<<~SQL),
        progress = CASE
                     WHEN challenge_progresses.progress > #{required} THEN EXCLUDED.progress
                     ELSE challenge_progresses.progress
                   END,
        completed = CASE
                      WHEN challenge_progresses.progress >= #{required}
                        OR EXCLUDED.progress >= #{required}
                        OR challenge_progresses.completed = true
                        THEN true
                      ELSE false
                    END
      SQL
      returning: %i[id completed awarded]
    )
  end

  def upsert_points(points, challenge)
    return unless topic_matches_quiz?(challenge)

    completed = points >= challenge.number_required
    required = challenge.number_required.to_i

    ChallengeProgress.upsert_all(
      [{progress: points, user_id: @quiz.user_id, challenge_id: challenge.id, completed: completed}],
      unique_by: %i[user_id challenge_id],
      on_duplicate: Arel.sql(<<~SQL),
        progress = challenge_progresses.progress + EXCLUDED.progress,
        completed = CASE
                      WHEN challenge_progresses.progress >= #{required}
                        OR (challenge_progresses.progress + EXCLUDED.progress) >= #{required}
                        OR challenge_progresses.completed = true
                        THEN true
                      ELSE false
                    END
      SQL
      returning: %i[id completed awarded]
    )
  end

  def topic_matches_quiz?(challenge)
    challenge.topic == @quiz.topic ||
      challenge.topic == @question_topic ||
      (@question_topic.present? && challenge.daily && challenge.topic.subject == @question_topic.subject)
  end

  def challenges
    Challenge.joins(:topic)
      .includes(topic: :subject)
      .where(topics: {subject_id: @quiz.subject})
      .where("end_date > ?", Time.current)
  end

  def complete_challenge(progress)
    progress.awarded = true
    progress.save

    progress.user.challenge_points = 0 if progress.user.challenge_points.nil?
    progress.user.challenge_points += progress.challenge.points
    progress.user.save
  end
end
