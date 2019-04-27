class SubjectMapsController < ApplicationController
  before_action :authenticate_admin!

  def update
    subject_map = SubjectMap.find(params[:id])
    authorize subject_map

    subject_name = subject_map_params[:name]
    subject_map.subject = Subject.where(name: subject_name).first
    head 403 unless subject_map.subject.present? || (subject_name == '')
    update_school(subject_map)
    subject_map.save
  end

  private

  def update_school(subject_map)
    subject_map.school.sync_status = 'needed'
    subject_map.school.save
  end

  def subject_map_params
    params.require(:subject_map).permit(:name)
  end
end
