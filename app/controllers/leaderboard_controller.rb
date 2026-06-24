# frozen_string_literal: true

class LeaderboardController < ApplicationController
  before_action :authenticate_user!
  before_action :set_subject_and_topic, only: :show

  def index
    @subjects = policy_scope(Subject)
    @subjects = current_user.subjects.uniq
    render 'subject_select'
  end

  def show
    authorize current_user
    @school_group = current_user.school.school_group
    if request.xhr?
      set_leaderboard_ajax_response_variables
    else
      set_leaderboard_variables
      return render 'subject_select' if @subject.blank?
    end

    render 'show'
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

  # Real names are safe here ONLY because this is scoped to current_user.school. If this is ever
  # broadened to other schools, switch to User#leaderboard_name_for (see Leaderboard::BuildLeaderboard).
  def set_classroom_winners
    @classroom_winners = ClassroomWinner.joins(:classroom, :user)
                                        .where(classroom: @classrooms)
                                        .pluck('classrooms.name', 'users.forename', 'users.surname', :score)
    @classroom_winners.map! { |w| [w[0], "#{w[1]} #{w[2][0]}", w[3]] }
  end

  def set_subject_and_topic
    @subject = Subject.find_by(name: leaderboard_params[:id])
    @topic = Topic.find(leaderboard_params[:topic]) if leaderboard_params[:topic].present?
  end

  def set_leaderboard_variables
    @subjects = current_user.subjects.uniq
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
    @user_data = { id: current_user.id,
                   role: current_user.role,
                   school: current_user.school.name,
                   classrooms: current_user.enrollments.joins(:classroom).pluck('classrooms.name') }
                 .merge(equipped_cosmetics)
  end

  # Equipped identity cosmetics for the current user's own leaderboard row (Plan 01, Phase 4). The
  # avatar emblem is server-rendered to an inline SVG string; the name is only wrapped in
  # nameplate/name-effect spans when a non-default cosmetic is equipped (so a plain row's text
  # layout is unchanged). Cosmetic-only — never affects scoring or ranking.
  def equipped_cosmetics
    { avatar_svg: equipped_avatar_svg }.merge(equipped_name_classes)
  end

  def equipped_avatar_svg
    helpers.glyph(helpers.equipped_avatar_glyph(current_user), size: 20,
                                                               color: helpers.equipped_avatar_color(current_user))
  end

  def equipped_name_classes
    plate = current_user.equipped_value(:nameplate)
    effect = current_user.equipped_value(:name_effect)
    decorated = [plate, effect].any? { |value| value.present? && value != 'none' }
    { nameplate_class: decorated ? helpers.nameplate_class(plate) : '',
      name_effect_class: decorated ? helpers.name_effect_class(effect) : '',
      plate_accent: helpers.equipped_avatar_color(current_user) }
  end

  def leaderboard_params
    params.permit(:id, :topic, :school_group, :all_time, :format)
  end
end
