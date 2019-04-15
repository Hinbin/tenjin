class DashboardController < ApplicationController
  before_action :authenticate_user!

  def show
    authorize current_user # make it so that it checks if the school is permitted?
    @subjects = current_user.subjects

    if (current_user.student?)
      @challenges = Challenge.includes(:topic)
                            .where(topics: { subject_id: [@subjects.pluck(:id)] })
                            .includes(:challenge_progresses).where(challenge_progresses: {user_id: [current_user, nil]})
      @css_flavour = current_user.dashboard_style
      render 'student_dashboard'
    else
      @enrollments = current_user.enrollments
      render 'teacher_dashboard'
    end
  end
end
