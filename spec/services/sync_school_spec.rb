RSpec.describe SyncSchool, '#call' do
  def sync_school_with_wonde
    create(:default_subject_map, name:'Sociology')
    @add_school = AddSchool.new('2a550dc912f6a63488af42352b79c5961e87daf9', 'A852030759')
    @add_school.call
    @sync_school = SyncSchool.new('A852030759')
    @sync_school.call
  end

  context 'using the classroom data' do
    before do
      sync_school_with_wonde
    end

    it 'creates classrooms', :vcr do
      expect(Classroom.count).to be > 0
    end
    it 'updates a classroom'
    it 'updates the members of a classroom'
  end

  context 'using student data' do
    it 'creates student entries'
    it 'cpdates a students details'
  end

  context 'using employee data' do
    it 'creates employee entries'
    it 'updates the owner of a classroom'
  end

  context 'using subject data' do
  before do
    sync_school_with_wonde
  end
  
  it 'creates subject maps', :vcr do
    expect(SubjectMap.count).to be > 1
  end
end

  context 'when given updated subject data' do
    it 'updates a subject name', :vcr do
      create(:school, name: 'Outwood Grange Academy 1532082212', client_id: 'A852030759')
      create(:subject_map, client_subject_name: 'Test', client_id: 'A1209580994', school: School.first)
      sync_school_with_wonde
      expect(SubjectMap.where(client_id: 'A1209580994').first.client_subject_name).to eq('Sociology')
    end
    it 'uses default subject maps', :vcr do
      create(:default_subject_map)
      # Create a subject map that maps Sociology to Computer Science
      create(:default_subject_map, name: 'Sociology')
      sync_school_with_wonde
      expect(SubjectMap.where(client_subject_name: 'Sociology').first.subject.name).to eq('Computer Science')
    end
  end
end
