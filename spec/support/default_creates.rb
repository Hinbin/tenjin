# frozen_string_literal: true

RSpec.shared_context "with default_creates", shared_context: :metadata do
  let(:quiz_subject) { create(:subject) }
  let(:topic) { create(:topic, subject: quiz_subject) }
  let(:school) { create(:school) }

  let(:student) { create(:student, school: school) }
  let(:teacher) { create(:teacher, school: school) }
  let(:school_admin) { create(:school_admin, school: school) }
  let(:classroom) { create(:classroom, school: school, subject: quiz_subject) }

  let(:super_admin) { create(:super_admin) }
end
