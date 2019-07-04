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
      School::SyncSchool.new(@school).call
    else
      render 'new'
    end
  end

  def update
    if update_school_params[:reset_all].present? && update_school_params[:reset_all] == 'true'
      authorize @current_admin, policy_class: SchoolPolicy
      @result = User::ResetUserPasswords.new(@current_admin, @school).call
      @students = User.where(school: @school)
      render 'users/new_passwords'
    else
      authorize @school
      School::SyncSchool.new(@school).call
    end
  end

  def show
    authorize @school
    @asked_questions =
      AskedQuestion.joins(quiz: [{ user: :school }])
                   .where('asked_questions.correct IS NOT NULL AND schools.id = ?', @school.id).count
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
    params.permit(:reset_all)
  end
end
