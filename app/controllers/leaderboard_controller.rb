class LeaderboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @subjects = policy_scope(Subject)
    @subjects = current_user.subjects.uniq
    render 'subject_select'
  end

  def show
    set_subject_and_topic
    set_leaderboard_show_data
    authorize @current_user.school

    if @subject.blank?
      render 'subject_select'
    else
      @entries = Leaderboard::BuildLeaderboard.new(current_user, @subject, @topic).call
      set_topic_name
      render 'show'
    end
  end

  private

  def set_subject_and_topic
    @subject = Subject.where(name: leaderboard_params.dig(:id)).first
    @topic = Topic.where('id = ?', leaderboard_params[:topic]).first
  end

  def set_leaderboard_show_data
    @subjects = current_user.subjects.uniq
    @school = current_user.school.name
    gon.subject = @subject
    gon.school = @school
    gon.user = current_user.id
  end

  def set_topic_name
    @topic_name = if @topic.nil?
                    'All'
                  else
                    @topic.name
                  end
    gon.topic = @topic_name
  end

  def leaderboard_params
    params.permit(:id, :topic)
  end
end
