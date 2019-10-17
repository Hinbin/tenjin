# frozen_string_literal: true

class Quiz::AddLeaderboardPoint < ApplicationService
  def initialize(params)
    @quiz = params[:quiz]
    @user = @quiz.user
    @question = params[:question]
    @topic_score = @user.topic_scores.where(topic: @question.topic).first_or_initialize
  end

  def call
    return unless @quiz.counts_for_leaderboard

    add_points
    Leaderboard::BroadcastLeaderboardPoint.call(@topic_score)
  end

  def add_points
    @multiplier = Multiplier.where('score < ?', @quiz.streak).last.multiplier

    @topic_score.score = 0 if @topic_score.new_record?
    @topic_score.score += @multiplier.to_i
    Challenge::UpdateChallengeProgress.call(@quiz, 'number_of_points', @multiplier.to_i, @question.topic)

    @topic_score.save
  end
end
