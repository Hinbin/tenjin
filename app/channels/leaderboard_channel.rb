# frozen_string_literal: true

class LeaderboardChannel < ApplicationCable::Channel
  def subscribed
    return if params[:subject].blank?
    return if params[:school].blank?

    stream_from stream_string
  end

  # Streams are scoped per school (never per school_group) so a real-name live tick only ever
  # reaches subscribers in the broadcasting student's own school. Other-school rows on a trust
  # view are filled in — already pseudonymised — by the AJAX reload, not by live ticks.
  def stream_string
    subject = params[:subject]
    "leaderboard:#{subject}:#{params[:school]}"
  end

  def unsubscribed; end
end
