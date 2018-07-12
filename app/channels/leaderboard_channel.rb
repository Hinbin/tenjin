class LeaderboardChannel < ApplicationCable::Channel
  def subscribed
    return if params[:subject].blank?
    stream_from "leaderboard:#{params[:subject]}"
  end

  def unsubscribed; end
end
