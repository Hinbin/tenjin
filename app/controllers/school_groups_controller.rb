# frozen_string_literal: true

class SchoolGroupsController < ApplicationController
  before_action :authenticate_admin!

  def index
    @school_groups = policy_scope(SchoolGroup)
  end

  def show
    @school_group = authorize find_school_group
  end

  def new
    @school_group = SchoolGroup.new(name: "New Group")
    authorize @school_group
    render :show
  end

  def create
    school_group = SchoolGroup.new(school_group_params)
    authorize school_group
    school_group.save

    redirect_to school_groups_path
  end

  def update
    school_group = authorize find_school_group
    school_group.update(school_group_params)

    redirect_to school_groups_path
  end

  def destroy
    school_group = authorize find_school_group
    school_group.destroy
    redirect_to school_groups_path
  end

  private

  def find_school_group
    SchoolGroup.find(params[:id])
  end

  def school_group_params
    params.require(:school_group).permit(:name)
  end
end
