# frozen_string_literal: true

class SchoolsController < ApplicationController
  before_action :authenticate_admin!, only: %i[index new create update show]
  before_action :authenticate_user!, only: %i[sync]
  before_action :set_school, only: %i[show update show_employees sync]

  def index
    @schools = policy_scope(School).order(:name)
    @school_groups = policy_scope(SchoolGroup).order(:name)
  end

  def new
    @school = School.new
    authorize @school
  end

  def create
    @school = School::AddSchool.call(school_params)
    if @school.persisted?
      authorize @school
      redirect_to @school
      SyncSchoolJob.perform_later @school
    else
      render 'new'
    end
  end

  def update
    authorize @school
    @school.update_attributes(update_school_params)
    return head :ok if request.xhr?

    redirect_to schools_path
  end

  def sync
    authorize @school
    @school.update_attribute('sync_status', 'queued')
    SyncSchoolJob.perform_later @school
    redirect_to classrooms_path
  end

  def reset_all_passwords
    authorize current_user.school
    @result = User::ResetUserPasswords.call(current_user)
    if @result.success?
      @students = policy_scope(User).where(role: 'student').includes(enrollments: :classroom)
      @employees = policy_scope(User).where(role: 'employee')
      return render 'users/new_passwords'
    else
      flash[:alert] = @result.errors
      redirect_to index
    end
  end

  def show
    authorize @school
    @asked_questions =
      AskedQuestion.joins(quiz: [{ user: :school }])
                   .where('asked_questions.correct IS NOT NULL AND schools.id = ?', @school.id).count
    @homeworks_completed =
      HomeworkProgress.joins(user: :school)
                      .where('homework_progresses.completed = true AND schools.id = ?', @school.id).count
    @challenge_points_earned = User.where(school: @school).sum(:challenge_points)
    @school_admins = User.where(school: @school).with_role(:school_admin)
    @users = User.where(school: @school)
  end

  private

  def set_school
    @school = School.find(params[:id])
  end

  def school_params
    params.require(:school).permit(:client_id, :token)
  end

  def update_school_params
    params.require(:school).permit(:school_group_id, :permitted)
  end

  def reset_all_password_params
    params.permit(:reset_all)
  end
end
