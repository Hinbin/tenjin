# frozen_string_literal: true

class LeaderboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @subjects = policy_scope(current_user.subjects).distinct
    @dashboard_style = find_dashboard_style
    render "subject_select"
  end

  def show
    authorize current_user
    @subject = find_subject
    @topic = find_topic
    @school_group = current_user.school.school_group
    if request.xhr?
      set_leaderboard_ajax_response_variables
    else
      set_leaderboard_variables
      return render "subject_select" if @subject.blank?
    end

    render :show
  end

  private

  def build_leaderboard
    @entries = Leaderboard::BuildLeaderboard.call(current_user,
      leaderboard_params)
    @awards = LeaderboardAward.where(school: current_user.school, subject: @subject).group(:user_id).count
    @classrooms = Classroom.where(school: current_user.school, subject: @subject)
    set_subject_or_topic_name
    set_classroom_winners
  end

  def set_leaderboard_ajax_response_variables
    @subject = Subject.find_by(name: leaderboard_params[:id])
    build_leaderboard
    set_filter_data
    set_user_data
  end

  def set_subject_or_topic_name
    @name = @topic.present? ? @topic.name : @subject.name
  end

  def set_classroom_winners
    @classroom_winners = ClassroomWinner.joins(:classroom, :user)
      .where(classroom: @classrooms)
      .pluck("classrooms.name", "users.forename", "users.surname", :score)
    @classroom_winners.map! { |w| [w[0], "#{w[1]} #{w[2][0]}", w[3]] }
  end

  def find_subject
    Subject.find_by(name: leaderboard_params[:id])
  end

  def find_topic
    return nil if leaderboard_params[:topic].blank?

    Topic.find(leaderboard_params[:topic])
  end

  def set_leaderboard_variables
    @subjects = current_user.subjects.distinct
    @school = current_user.school
    cookies.encrypted[:user_id] = current_user.id
  end

  def set_filter_data
    @schools = if @school_group.present?
      School.where(school_group_id: @school_group).pluck(:name)
    else
      [current_user.school.name]
    end
    @classrooms = Classroom.where(school: current_user.school, subject: @subject).pluck(:name)
  end

  def set_user_data
    @user_data = {id: current_user.id,
                  role: current_user.role,
                  school: current_user.school.name,
                  classrooms: current_user.enrollments.joins(:classroom).pluck("classrooms.name")}
  end

  def leaderboard_params
    params.permit(:id, :topic, :school_group, :all_time, :format)
  end
end
