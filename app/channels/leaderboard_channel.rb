# frozen_string_literal: true

class LeaderboardChannel < ApplicationCable::Channel
  def subscribed
    return if params[:subject].blank?
    return if params[:school].blank?

    stream_from stream_string
  end

  def stream_string
    subject = params[:subject]
    location = params[:school_group].present? ? params[:school_group] : params[:school]
    "leaderboard:#{subject}:#{location}"
  end

  def unsubscribed; end
end
