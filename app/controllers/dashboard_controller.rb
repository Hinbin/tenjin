class DashboardController < ApplicationController
  before_action :authenticate_user!

  def show
    authorize current_user # make it so that it checks if the school is permitted?
    @subjects = current_user.subjects

    if (current_user.student?)
      @css_flavour = current_user.dashboard_style
      @homework_progress =  HomeworkProgress.includes(:homework, homework: :topic, homework: [topic: :subject])
                                            .where('user_id = ? AND ( completed = false OR ( completed = true AND homeworks.due_date > ? )) ', current_user, DateTime.now - 1.week)
                                            .order('homeworks.due_date')
                                            .limit(15)
      @challenges =  Challenge.includes(:topic)
                              .where(topics: { subject_id: [@subjects.pluck(:id)] })
                              .includes(:challenge_progresses).where(challenge_progresses: {user_id: [current_user, nil]})
      render 'student_dashboard'
    else
      @enrollments = Enrollment.includes(:classroom, :subject).where(user: current_user)
      render 'teacher_dashboard'
    end
  end
end
