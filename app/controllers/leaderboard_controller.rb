class LeaderboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @subjects = policy_scope(Subject)
    @subjects = current_user.subjects.uniq
    @css_flavour = current_user.dashboard_style
    render 'subject_select'
  end

  def show
    set_subject_and_topic
    set_leaderboard_variables
    set_javascript_variables
    authorize @current_user

    return render 'subject_select' if @subject.blank?

    @entries = Leaderboard::BuildLeaderboard.new(current_user,
                                                 @subject,
                                                 @topic,
                                                 leaderboard_params).call
    set_topic_name
    render 'show'
  end

  private

  def set_subject_and_topic
    @subject = Subject.where(name: leaderboard_params.dig(:id)).first
    @topic = Topic.where('id = ?', leaderboard_params.dig(:topic)).first
  end

  def set_leaderboard_variables
    @subjects = current_user.subjects.uniq
    @school = current_user.school
    cookies.encrypted[:user_id] = current_user.id
  end

  def set_javascript_variables
    gon.subject = @subject
    gon.school = @school
    gon.school_group = @school.school_group
    gon.user = current_user.id
    gon.params = leaderboard_params
    gon.path = leaderboard_path(id: @subject.name)
  end

  def set_topic_name
    @topic_name = if @topic.nil?
                    'All'
                  else
                    gon.topic = @topic.id
                    @topic.name
                  end
  end

  def leaderboard_params
    params.permit(:id, :topic, :school_group, :all_time, :format)
  end
end
