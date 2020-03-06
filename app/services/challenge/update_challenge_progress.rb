# frozen_string_literal: true

class Challenge::UpdateChallengeProgress < ApplicationService
  def initialize(quiz, update_type, number_to_add = 0, question_topic = nil)
    @quiz = quiz
    @update_type = update_type
    @number_to_add = number_to_add
    @question_topic = question_topic
  end

  def call
    challenges.find_each do |c|
      cp = ChallengeProgress.find_or_create_by(user: @quiz.user, challenge: c)
      next if cp.completed

      progress = case c.challenge_type
                 when 'number_correct' then check_number_correct(c) #upsert_progress?
                 when 'streak' then check_streak(c)
                 when 'number_of_points' then check_number_of_points(c, cp) # upsert_points?
                 end
      next unless progress > cp.progress

      cp.progress = progress
      complete_challenge(cp) if progress >= c.number_required

      cp.save
    end
  end

  protected

  def upsert_progress
    binds = [[nil, score], [nil, user], [nil, topic]]
    TopicScore.connection.exec_insert <<~SQL, 'Upsert topic score', binds
      INSERT INTO "topic_scores"("score","user_id","topic_id","created_at","updated_at")
      VALUES ($1, $2, $3, current_timestamp, current_timestamp)
      ON CONFLICT ("user_id","topic_id")
      DO UPDATE SET "score"=topic_scores.score + $1,"updated_at"=excluded."updated_at"
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

  def check_number_of_points(challenge, cp)
    unless @question_topic == challenge.topic || (challenge.daily && @question_topic.subject == challenge.topic.subject)
      return 0
    end

    cp.progress + @number_to_add
  end

  def complete_challenge(progress)
    progress.completed = true

    progress.user.challenge_points = 0 if progress.user.challenge_points.nil?
    progress.user.challenge_points += progress.challenge.points
    progress.user.save
  end
end
