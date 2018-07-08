class LeaderboardChannel < ApplicationCable::Channel
  def subscribed
    return if params[:subject].blank?
    stream_from params[:subject].to_s
  end

  def unsubscribed; end
end
