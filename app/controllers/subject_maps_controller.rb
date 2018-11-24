class SubjectMapsController < ApplicationController
  before_action :authenticate_admin!

  def update
    subject_map = SubjectMap.find(params[:id])
    authorize subject_map

    subject_name = subject_map_params[:name]
    subject_map.subject = Subject.where(name: subject_name).first
    subject_map.save
  end

  private

  def subject_map_params
    params.require(:subject_map).permit(:name)
  end
end
