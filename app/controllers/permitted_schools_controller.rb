class PermittedSchoolsController < ApplicationController
  include PermittedSchoolsHelper
  before_action :authenticate_admin!

  def index
    @permitted_schools = policy_scope(PermittedSchool)
  end

  def show
    authorize @permitted_school = PermittedSchool.find(params[:id])
  end

  def new
    authorize @permitted_school = PermittedSchool.new
  end

  def edit
    authorize @permitted_school = PermittedSchool.find(params[:id])
  end

  def create
    authorize @permitted_school = PermittedSchool.new(permitted_school_params)
    @permitted_school.name = add_school(@permitted_school.token, @permitted_school.school_id)

    if @permitted_school.save
      redirect_to @permitted_school
    else
      render 'new'
    end
  end

  def update
    authorize @permitted_school = PermittedSchool.find(params[:id])

    if @permitted_school.update(permitted_school_params)
      redirect_to @permitted_school
    else
      render 'edit'
    end
  end

  def destroy
    authorize @permitted_school = PermittedSchool.find(params[:id])
    @permitted_school.destroy

    redirect_to permitted_schools_path
  end

  private

  def permitted_school_params
    params.require(:permitted_school).permit(:school_id, :name, :token)
  end
end
