class LeaderboardController < ApplicationController
  before_action :authenticate_user!
  before_action :set_subject, only: %i[show]

  def index
    @subjects = policy_scope(Subject)
    @subjects = current_user.subjects.uniq
    render 'subject_select'
  end

  def show
    @subject = Subject.where(name: leaderboard_params.dig(:id)).first
    @subjects = current_user.subjects.uniq
    @school = current_user.school.name
    authorize @current_user.school
    gon.subject = @subject
    gon.school = @school
    if @subject.blank?
      render 'subject_select'
    else
      @topic = Topic.where('id = ?', leaderboard_params[:topic]).first
      if @topic.blank?
        @topic_name = 'All'
        gon.topic = nil
        @entries = TopicScore
                   .joins(user: :school, topic: :subject)
                   .group('user_id', 'forename', 'surname', 'schools.name')
                   .where('school_id = ?', current_user.school.id)
                   .where('subject_id = ?', @subject.id)
                   .sum(:score)
      else
        @topic_name = @topic.name
        gon.topic = @topic.id
        @entries = TopicScore
                   .joins(user: :school, topic: :subject)
                   .group('user_id', 'forename', 'surname', 'schools.name')
                   .where('school_id = ?', current_user.school.id)
                   .where('topic_id = ?', @topic.id)
                   .sum(:score)
      end

      render 'show'
    end
  end

  private

  def leaderboard_params
    params.permit(:id, :topic)
  end

  def set_subject; end
end
