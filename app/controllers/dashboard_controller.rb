class DashboardController < ApplicationController
  before_action :authenticate_user!

  def show
    authorize current_user # make it so that it checks if the school is permitted?
    @subjects = current_user.subjects

    if current_user.student?
      @css_flavour = current_user.dashboard_style
      student_homework_progress
      student_challenges
      render 'student_dashboard'
    else
      teacher_enrollments
      render 'teacher_dashboard'
    end
  end

  private

  def student_homework_progress
    @homework_progress = HomeworkProgress.includes(:homework, homework: [topic: :subject])
                                         .where('user_id = ? AND ( completed = false OR ( completed = true AND
                                          homeworks.due_date > ? )) ', current_user, Time.now - 1.week)
                                         .order('homeworks.due_date')
                                         .limit(15)
  end

  def student_challenges
    @challenges = Challenge.includes(:topic)
                           .where(topics: { subject_id: [@subjects.pluck(:id)] })
                           .includes(:challenge_progresses)
                           .where(challenge_progresses: { user_id: [current_user, nil] })
  end

  def teacher_enrollments
    @enrollments = Enrollment.includes(:classroom, :subject).where(user: current_user)
  end
end
