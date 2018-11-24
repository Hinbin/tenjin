class SchoolsController < ApplicationController
  before_action :authenticate_admin!

  def index
    @schools = policy_scope(School)
  end

  def new
    @school = School.new
    authorize @school
  end

  def create
    add_school = AddSchool.new(school_params)
    @school = add_school.call
    if @school.persisted?
      authorize @school
      redirect_to @school
      sync_school = SyncSchool.new(@school)
      sync_school.call
    else
      render 'new'
    end
  end

  def show
    @school = School.find(params[:id])
    @asked_questions =
      AskedQuestion.joins(quiz: [{ user: :school }])
                   .where('asked_questions.correct IS NOT NULL AND schools.id = ?', @school.id).count
    authorize @school
  end

  private

  def school_params
    params.require(:school).permit(:client_id, :token)
  end
end
