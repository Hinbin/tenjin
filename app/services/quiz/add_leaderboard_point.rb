# frozen_string_literal: true

class Quiz::AddLeaderboardPoint < ApplicationService
  def initialize(params)
    super()
    @quiz = params[:quiz]
    @user = @quiz.user
    @question = params[:question]
    @answer_seconds = params[:answer_seconds]
    @bits = params.fetch(:bits, 1)
  end

  # Returns the leaderboard points awarded for this answer (0 when the quiz doesn't count), so the
  # caller can surface the per-question award and keep a running per-quiz total for the HUD.
  def call
    return 0 unless @quiz.counts_for_leaderboard

    multiplier = Multiplier.where('score < ?', @quiz.streak).order(score: :desc).pick(:multiplier) || 1
    points = multiplier * @bits
    @quiz.leaderboard_points += points
    upsert_score(@question.topic.id, @user.id, points)

    Challenge::UpdateChallengeProgress.call(@quiz, multiplier, @question.topic, @answer_seconds)
    Leaderboard::BroadcastLeaderboardPoint.call(@question.topic, @user)
    points
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
