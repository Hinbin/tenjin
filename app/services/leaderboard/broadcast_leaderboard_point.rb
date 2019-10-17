# frozen_string_literal: true

class Leaderboard::BroadcastLeaderboardPoint < ApplicationService
  def initialize(topic_score)
    @subject = topic_score.subject
    @user = topic_score.user
    @topic_score = topic_score
  end

  def call
    LeaderboardChannel.broadcast_to(channel_name, json_data)
  end

  protected

  def channel_name
    school = @user.school
    location = if school.school_group_id.present?
                 school.school_group.name
               else
                 school.name
               end
    "#{@subject.name}:#{location}"
  end

  def json_data
    {
      id: @user.id,
      name: "#{@user.forename} #{@user.surname[0]}",
      school_name: @user.school.name,
      topic: @topic_score.topic.id,
      topic_score: @topic_score.score,
      subject_score: subject_score,
      classroom_names: @user.classrooms.all.pluck(:name)
    }
  end

  def subject_score
    TopicScore.joins(:subject)
              .where('user_id = ? AND subject_id = ?', @user.id, @subject.id)
              .sum(:score)
  end
end
