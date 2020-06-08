# frozen_string_literal: true

class Quiz::AddLeaderboardPoint < ApplicationService
  def initialize(params)
    @quiz = params[:quiz]
    @user = @quiz.user
    @question = params[:question]
  end

  def call
    return unless @quiz.counts_for_leaderboard

    multiplier = Multiplier.where('score < ?', @quiz.streak).order(score: :desc).pick(:multiplier)
    upsert_score(@question.topic.id, @user.id, multiplier)

    Challenge::UpdateChallengeProgress.call(@quiz, multiplier, @question.topic)
    Leaderboard::BroadcastLeaderboardPoint.call(@question.topic, @user)
  end

  protected

  def upsert_score(topic, user, score)
    binds = [[nil, score], [nil, user], [nil, topic]]
    TopicScore.connection.exec_insert <<~SQL, 'Upsert topic score', binds
      INSERT INTO "topic_scores"("score","user_id","topic_id","created_at","updated_at")
      VALUES ($1, $2, $3, current_timestamp, current_timestamp)
      ON CONFLICT ("user_id","topic_id")
      DO UPDATE SET "score"=topic_scores.score + $1,"updated_at"=excluded."updated_at"
    SQL
  end
end
