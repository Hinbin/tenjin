# frozen_string_literal: true

class Leaderboard::BroadcastLeaderboardPoint < ApplicationService
  def initialize(topic, user)
    @topic = topic
    @user = user
  end

  def call
    @topic_score, @subject_score = scores
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
    "#{@topic.subject.name}:#{location}"
  end

  def json_data
    {
      id: @user.id,
      name: "#{@user.forename} #{@user.surname[0]}",
      school_name: @user.school.name,
      topic: @topic.id,
      topic_score: @topic_score,
      subject_score: @subject_score,
      classroom_names: @user.classrooms.all.pluck(:name)
    }
  end

  def scores
    s_score = TopicScore.arel_table[:score].sum
    t_score = TopicScore.select(s_score)
      .where(user_id: @user, topic_id: @topic)
      .arel

    TopicScore.joins(:topic)
      .where(user_id: @user)
      .where(subject_topics.arel.exists)
      .pick(s_score.as('subject_score'), t_score.as('topic_score'))
  end

  private

  def subject_topics
    Topic.select(1)
      .from('topics t2')
      .where(t2: { id: @topic })
      .where('t2.subject_id = topics.subject_id')
  end
end
