class SchoolsController < ApplicationController
  before_action :authenticate_admin!, only: %i[index new create show]
  before_action :authenticate_user!, only: %i[update]
  before_action :set_school, only: %i[show update show_employees]

  def index
    @schools = policy_scope(School)
  end

  def new
    @school = School.new
    authorize @school
  end

  def create
    @school = School::AddSchool.new(school_params).call
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
    @school.update_attribute('sync_status', 'queued')
    SyncSchoolJob.perform_later @school
    redirect_to classrooms_path
  end

  def reset_all_passwords
    authorize current_user.school
    @result = User::ResetUserPasswords.new(current_user).call
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
    @school_admins = User.where(school: @school, role: 'school_admin')
  end

  def show_employees
    authorize @school
    @school_admins = User.where(school: @school, role: 'school_admin')
    @employees = User.where(school: @school, role: 'employee').or @school_admins
    render 'school_employees'
  end

  private

  def set_school
    @school = School.find(params[:id])
  end

  def school_params
    params.require(:school).permit(:client_id, :token)
  end

  def update_school_params
    params.permit(:id, :role, :user_id, :authenticity_token)
  end

  def reset_all_password_params
    params.permit(:reset_all)
  end

end
