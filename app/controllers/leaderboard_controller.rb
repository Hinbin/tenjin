class LeaderboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @subjects = policy_scope(Subject)
    @subjects = current_user.subjects.uniq
    @css_flavour = find_dashboard_style
    render 'subject_select'
  end

  def show
    authorize current_user

    if request.xhr?
      @subject = Subject.where(name: leaderboard_params[:id]).first
      build_leaderboard
    else
      set_subject_and_topic
      set_leaderboard_variables
      set_javascript_variables
      return render 'subject_select' if @subject.blank?

      set_topic_name
    end

    render 'show'
  end

  private

  def build_leaderboard
    @entries = Leaderboard::BuildLeaderboard.new(current_user,
                                                 leaderboard_params).call
    @awards = LeaderboardAward.where(school: current_user.school, subject: @subject).group(:user_id).count
  end

  def set_subject_and_topic
    @subject = Subject.where(name: leaderboard_params[:id]).first
    @topic = Topic.find(leaderboard_params[:topic]) if leaderboard_params[:topic].present?
  end

  def set_leaderboard_variables
    @subjects = current_user.subjects.uniq
    @school = current_user.school
    cookies.encrypted[:user_id] = current_user.id
  end

  def set_javascript_variables
    gon.subject = @subject
    gon.school = { id: @school.id, name: @school.name }
    gon.school_group = { id: @school.school_group.id, name: @school.school_group.name } if @school.school_group.present?
    gon.user = current_user.id
    gon.params = leaderboard_params
    set_path
  end

  def set_path
    gon.path = if @topic.present?
                 leaderboard_path(id: @subject.name, topic: @topic.id)
               else
                 leaderboard_path(id: @subject.name)
               end
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
