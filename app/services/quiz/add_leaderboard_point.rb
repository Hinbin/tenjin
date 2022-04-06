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

  def upsert_score(topic_id, user_id, score)
    TopicScore.upsert_all([
      { topic_id:, user_id:, score: }
    ],
                          unique_by: %w[user_id topic_id],
                          on_duplicate: Arel.sql("score=topic_scores.score + #{score}"))
  end
end
