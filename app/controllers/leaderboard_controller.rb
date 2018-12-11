class LeaderboardController < ApplicationController
  before_action :authenticate_user!
  before_action :set_subject, only: %i[show]

  def show
    @subject = Subject.where(name: leaderboard_params.dig(:subject)).first
    @subjects = current_user.subjects.uniq
    @school = current_user.school.name
    authorize @current_user.school
    gon.subject = @subject
    gon.school = @school
    if @subject.blank?
      render 'subject_select'
    else
      @entries = TopicScore
                 .joins(user: :school, topic: :subject)
                 .group('user_id', 'forename', 'surname', 'schools.name')
                 .where('school_id = ?', current_user.school.id)
                 .sum(:score)

      render 'show'
    end
  end

  private

  def leaderboard_params
    params.permit(:subject)
  end

  def set_subject; end
end
