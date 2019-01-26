class LeaderboardChannel < ApplicationCable::Channel
  def subscribed
    return if params[:subject].blank?
    return if params[:school].blank?

    stream_string = "leaderboard:#{params[:subject][:name] + ':'}"
    stream_string += params[:school_group].present? ? params[:school_group][:name] : params[:school][:name]
    stream_from stream_string
  end

  def unsubscribed; end
end
