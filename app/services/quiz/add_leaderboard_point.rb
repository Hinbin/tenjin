# frozen_string_literal: true

class Quiz::AddLeaderboardPoint < ApplicationService
  def initialize(params)
    @quiz = params[:quiz]
    @user = @quiz.user
    @question = params[:question]
  end

  def call
    return unless @quiz.counts_for_leaderboard

    multiplier = Multiplier.for_streak(@quiz.streak)
    upsert_score(@question.topic.id, @user.id, multiplier)

    Challenge::UpdateChallengeProgress.call(@quiz, multiplier, @question.topic)
    Leaderboard::BroadcastLeaderboardPoint.call(@question.topic, @user)
  end

  protected

  def upsert_score(topic, user, score)
    TopicScore.upsert_all(
      [{score: score, user_id: user, topic_id: topic}],
      unique_by: %i[user_id topic_id],
      on_duplicate: Arel.sql("score = topic_scores.score + EXCLUDED.score, updated_at = EXCLUDED.updated_at")
    )
  end
end
