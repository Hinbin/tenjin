RSpec.describe SyncSchool, '#call', :vcr do
  let(:school_token) { '2a550dc912f6a63488af42352b79c5961e87daf9' }
  let(:school_id) { 'A852030759' }
  let(:subject_to_map) { 'Sociology' }
  let(:classroom_client_id) { 'A1906124304' }
  let(:classroom_name) { 'SOC 2' }
  let(:school_name) { 'Outwood Grange Academy 1532082212' }
  let(:student_upi) { '1479cf1d289684f08600c9ad1f6406fc' }
  let(:student_name) { 'Leo' }
  let(:employee_upi) { 'caea4baa5b7adac73ab1259987d2bcc0' }
  let(:employee_name) { 'Emma' }

  def sync_school_with_wonde
    create(:default_subject_map, name: subject_to_map)
    add_school = AddSchool.new(school_token, school_id)
    add_school.call
    sync_school = SyncSchool.new(school_id)
    sync_school.call
  end

  context 'with classroom data' do
    before do
      sync_school_with_wonde
    end

    it 'creates classrooms' do
      expect(Classroom.count).to be > 0
    end

    it 'creates classooms with the correct client id' do
      expect(Classroom.first.client_id).to eq classroom_client_id
    end

    it 'creates classrooms for the correct school' do
      expect(Classroom.first.school.client_id).to eq school_id
    end

    it 'creates the classrooms for subjects that have been mapped' do
      expect(Classroom.first.subject.name).to eq 'Computer Science'
    end

    it 'enrolls students into the classroom' do
      expect(Enrollment.first.classroom.name).to eq classroom_name
    end

    it 'does not duplicate enrollments' do
      sync_school_with_wonde
      expect(Enrollment.where(user_id: User.first).count).to eq(1)
    end
  end

  context 'when receiving updated classroom data' do
    before do
      school = create(:school, client_id: school_id)
      create(:classroom, client_id: classroom_client_id, school: school)
    end

    it 'updates a classroom' do
      sync_school_with_wonde
      expect(Classroom.first.name).to eq classroom_name
    end

    it 'removes enrollments that no longer exist' do
      student = create(:student)
      create(:enrollment, classroom: Classroom.first, user: student)
      sync_school_with_wonde
      expect(Enrollment.where(user: student)).to be_empty
    end
  end

  context 'with student data' do
    before do
      sync_school_with_wonde
    end

    it 'creates student entries' do
      expect(User.where(role: 'student').count).to be > 0
    end

    it 'creates employee entries' do
      expect(User.where(role: 'employee').count).to be > 0
    end

    it 'links a student to a school' do
      expect(User.first.school.name).to eq(school_name)
    end
  end

  context 'when given updated student data' do
    it 'updates student details' do
      create(:student, upi: student_upi)
      sync_school_with_wonde
      expect(User.where(upi: student_upi).first.forename).to eq(student_name)
    end
  end

  context 'with a new teacher assigned to classroom' do
    before do
      school = create(:school, client_id: school_id)
      classroom = create(:classroom, client_id: classroom_client_id, school: school)
      employee = create(:employee)
      create(:enrollment, classroom: classroom, user: employee)
      sync_school_with_wonde
    end

    it 'updates the owner of a classroom' do
      expect(Classroom.where(client_id: classroom_client_id).first.users
      .where(role: 'employee').first.upi).to eq(employee_upi)
    end
  end

  context 'with updated employee data' do
    it 'updates employee details' do
      create(:employee, upi: employee_upi)
      sync_school_with_wonde
      expect(User.where(upi: employee_upi).first.forename).to eq(employee_name)
    end
  end

  context 'with subject data' do
    before do
      sync_school_with_wonde
    end

    it 'creates subject maps' do
      expect(SubjectMap.count).to be > 1
    end
  end

  context 'when given updated subject data' do
    it 'updates a subject name' do
      create(:school, name: school_name, client_id: school_id)
      create(:subject_map, client_subject_name: 'Test', client_id: 'A1209580994', school: School.first)
      sync_school_with_wonde
      expect(SubjectMap.where(client_id: 'A1209580994').first.client_subject_name).to eq(subject_to_map)
    end
    it 'uses default subject maps' do
      create(:default_subject_map)
      # Create a subject map that maps Sociology to Computer Science
      create(:default_subject_map, name: subject_to_map)
      sync_school_with_wonde
      expect(SubjectMap.where(client_subject_name: subject_to_map).first.subject.name).to eq('Computer Science')
    end
  end

  it 'handles deletions'
end
