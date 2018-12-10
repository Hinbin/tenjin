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
    authorize @school
    School::SyncSchool.new(@school).call
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
end
