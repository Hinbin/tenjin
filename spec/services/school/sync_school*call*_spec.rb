require 'rails_helper'

RSpec.describe School::SyncSchool, '#call', :vcr do
  include_context 'api_data'
  include_context 'wonde_test_data'

  let(:sociology_class) { Classroom.where(client_id: classroom_client_id).first }

  def sync_school_with_wonde
    school = School::AddSchool.new(school_params).call
    perform_enqueued_jobs do
      SyncSchoolJob.perform_later school
    end
  end

  context 'with classroom data' do
    before do
      sync_school_with_wonde
    end

    it 'creates classrooms' do
      expect(Classroom.count).to be > 0
    end

    it 'creates classooms with the correct client id' do
      expect(Classroom.where(client_id: classroom_client_id, name: classroom_name).count).to eq 1
    end

    it 'creates classrooms for the correct school' do
      expect(sociology_class.school.client_id).to eq school_id
    end

    it 'enrolls students into the classroom' do
      sociology_class.update_attribute('subject', create(:subject))
      sync_school_with_wonde
      expect(sociology_class.enrollments.count).to be > 0
    end

    it 'does not duplicate enrollments' do
      sociology_class.update_attribute('subject', create(:subject))
      sync_school_with_wonde
      sync_school_with_wonde
      expect(Enrollment.where(user_id: User.first).count).to eq(1)
    end

    it 'disables old classrooms' do
      create(:classroom, school: School.first, client_id: '1234')
      sync_school_with_wonde
      expect(Classroom.where(client_id: '1234').first.disabled).to eq true
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
      student = create(:student, upi: '1234')
      create(:enrollment, classroom: Classroom.first, user: student)
      sync_school_with_wonde
      expect(Enrollment.where(user: student)).to be_empty
    end
  end

  context 'with student data' do
    before do
      sync_school_with_wonde
      sociology_class.update_attribute('subject', create(:subject))
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
      create(:student, forename: 'test', upi: student_upi)
      sync_school_with_wonde
      sociology_class.update_attribute('subject', create(:subject))
      sync_school_with_wonde
      expect(User.where(upi: student_upi).first.forename).to eq(student_forename)
    end
  end

  context 'with a new teacher assigned to classroom' do
    before do
      school = create(:school, client_id: school_id)
      classroom = create(:classroom, client_id: classroom_client_id, school: school)
      employee = create(:user, role: 'employee')
      create(:enrollment, classroom: classroom, user: employee)
      sync_school_with_wonde
    end

    it 'updates the owner of a classroom' do
      expect(Classroom.where(client_id: classroom_client_id).first.users
      .where(role: 'employee').first.upi).to eq(employee_upi)
    end
  end

  context 'with updated employee data' do
    before do
      create(:teacher, upi: employee_upi)
      sync_school_with_wonde
      sociology_class.update_attribute('subject', create(:subject))
      sync_school_with_wonde
    end

    it 'updates employee details' do

      expect(User.where(upi: employee_upi).first.forename).to eq(employee_name)
    end
  end

  it 'handles deletions'
end
