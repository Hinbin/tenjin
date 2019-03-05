class DashboardController < ApplicationController
  before_action :authenticate_user!

  def show
    authorize current_user # make it so that it checks if the school is permitted?
    @subjects = current_user.subjects
    @challenges = Challenge.joins(:topic).where(topics: { subject_id: [@subjects.pluck(:id)] })
    gon.quiz_path = quizzes_path
  end
end
