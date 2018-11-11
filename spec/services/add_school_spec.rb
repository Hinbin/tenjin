require 'rails_helper'

RSpec.describe AddSchool, '#new' do
  it 'Create a Wonde API school object', :vcr do
    @add_school = AddSchool.new('2a550dc912f6a63488af42352b79c5961e87daf9', 'A852030759')
    expect(@add_school).not_to be_blank
  end
end

RSpec.describe AddSchool, '#call' do
  def update_school_from_wonde
    @add_school = AddSchool.new('2a550dc912f6a63488af42352b79c5961e87daf9', 'A852030759')
    @add_school.call
  end

  def school_in_db
    School.find_by(name: 'Outwood Grange Academy 1532082212')
  end

  context 'using the school information' do
    it 'Creates a school', :vcr do
      update_school_from_wonde
      expect(school_in_db.name).to eq 'Outwood Grange Academy 1532082212'
    end
    it 'Prevents a non-permitted school from being added'
    it 'Updates a school name', :vcr do
      create(:school, name: 'Not outwood', client_id: 'A852030759')
      update_school_from_wonde
      school_found = school_in_db
      expect(School.count).to eq(1)
      expect(school_found.name).to eq 'Outwood Grange Academy 1532082212'
    end
  end

  context 'using the subject information' do
    it 'Creates subjects ready to be mapped', :vcr do
      update_school_from_wonde
      expect(SubjectMap.count).to be > 1
    end
    it 'Updates a subject name', :vcr do
      create(:school, name: 'Outwood Grange Academy 1532082212', client_id: 'A852030759')
      create(:subject_map, client_subject_name: 'Test', client_id: 'A1209580994', school: School.first )
      update_school_from_wonde
      expect(SubjectMap.where(client_id: 'A1209580994').first.client_subject_name).to eq('Sociology')
    end
    it 'Uses default subject maps', :vcr do
      create(:default_subject_map)
      # Create a subject map that maps Sociology to Computer Science
      create(:default_subject_map, name: 'Sociology')
      update_school_from_wonde
      expect(SubjectMap.where(client_subject_name: 'Sociology').first.subject.name).to eq('Computer Science')
    end
  end

  context 'using the classroom data' do
    it 'Creates classrooms'
    it 'Updates a classroom'
    it 'Updates the members of a classroom'
  end

  context 'using student data' do
    it 'Creates student entries'
    it 'Updates a students details'
  end

  context 'using employee data' do
    it 'Creates employee entries'
    it 'Updates the owner of a classroom'
  end

  it 'Uses default maps if present'
end
