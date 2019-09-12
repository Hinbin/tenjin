class SchoolsController < ApplicationController
  before_action :authenticate_admin!
  before_action :set_school, only: %i[show update]

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
    if update_school_params[:role].present? && update_school_params[:user_id].present?
      authorize @current_admin, policy_class: SchoolPolicy
      User.find(update_school_params[:user_id]).update_attribute('role', update_school_params[:role])
    else
      authorize @school
      @school.update_attribute('sync_status', 'queued')
      SyncSchoolJob.perform_later @school
      redirect_to schools_path
    end
  end

  def show
    authorize @school
    @asked_questions =
      AskedQuestion.joins(quiz: [{ user: :school }])
                   .where('asked_questions.correct IS NOT NULL AND schools.id = ?', @school.id).count
    @school_admins = User.where(school: @school, role: 'school_admin')
    return unless school_show_params[:show_employees] == 'true'

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

  def pundit_user
    current_admin
  end

  def update_school_params
    params.permit(:id, :reset_all, :role, :user_id, :authenticity_token)
  end

  def school_show_params
    params.permit(:id, :show_employees)
  end
end
