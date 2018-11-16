class LeaderboardChannel < ApplicationCable::Channel
  def subscribed
    return if params[:subject].blank?
    return if params[:school].blank?

    stream_from "leaderboard:#{params[:subject] + ':' + params[:school]}"
  end

  def unsubscribed; end
end
