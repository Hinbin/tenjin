class LeaderboardChannel < ApplicationCable::Channel
  def subscribed
    return if params[:subject].blank?
    return if params[:school].blank?
    subject = params[:subject]

    stream_from "leaderboard:#{subject[:name] + ':' + params[:school]}"
  end

  def unsubscribed; end
end
