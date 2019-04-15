RSpec.shared_context 'default_creates', shared_context: :metadata do
  let(:subject) { create(:subject) }
  let(:topic) { create(:topic, subject: subject) }
  let(:school) { create(:school) }

  let(:student) { create(:student, school: school) }
  let(:teacher) { create(:teacher, school: school) }
  let(:classroom) { create(:classroom, school: school, subject: subject) }

  let(:second_school) { create(:school, school_group: School.first.school_group) }
  let(:second_school_student) { User.where(school: second_school).first }
  let(:second_school_student_name) { initialize_name second_school_student }

  let(:student_different_school_group) {create(:student)}
  let(:school_without_school_group ) {create(:school, school_group: nil)}
end