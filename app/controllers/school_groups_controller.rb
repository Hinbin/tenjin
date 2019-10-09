class SchoolGroupsController < ApplicationController
  before_action :authenticate_admin!
  before_action :set_school_group, only: %i[show update destroy]

  def index
    @school_groups = policy_scope(SchoolGroup)
  end

  def new
    @school_group = SchoolGroup.new(name: 'New Group')
    authorize @school_group
    render :show
  end

  def show 
    authorize @school_group
  end

  def update
    authorize @school_group
    @school_group.update_attributes(school_group_params)
    @school_group.save

    redirect_to school_groups_path
  end

  def create
    @school_group = SchoolGroup.new(school_group_params)
    authorize @school_group
    @school_group.save

    redirect_to school_groups_path
  end

  def destroy
    authorize @school_group
    @school_group.destroy
    redirect_to school_groups_path
  end

  private

  def set_school_group
    @school_group = SchoolGroup.find(params[:id])
  end

  def school_group_params
    params.require(:school_group).permit(:name)
  end

end
