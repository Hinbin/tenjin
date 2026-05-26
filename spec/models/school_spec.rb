# frozen_string_literal: true

require "rails_helper"

RSpec.describe School do
  it "has a valid factory" do
    expect(build(:school)).to be_valid
  end

  describe "validations" do
    subject { build(:school) }

    it { is_expected.to validate_presence_of(:client_id) }
    it { is_expected.to validate_uniqueness_of(:client_id) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:token) }
  end

  describe "#start_sync" do
    let(:school) { create(:school) }

    it "sets sync_status to syncing" do
      school.start_sync
      expect(school.reload).to be_syncing
    end

    context "with mixed user roles" do
      let!(:student) { create(:student, school: school) }
      let!(:employee) { create(:teacher, school: school) }
      let!(:school_admin) { create(:school_admin, school: school) }
      before { school.start_sync }

      it "disables non-admin users but not school admins" do
        expect([student.reload, employee.reload]).to all(be_disabled)
        expect(school_admin.reload).not_to be_disabled
      end
    end

    context "with classrooms and enrollments" do
      let!(:classroom) { create(:classroom, school: school) }
      let!(:student) { create(:student, school: school) }
      let!(:enrollment) { create(:enrollment, classroom: classroom, user: student) }
      before { school.start_sync }

      it "disables all classrooms" do
        expect(classroom.reload).to be_disabled
      end

      it "destroys all enrollments" do
        expect(Enrollment.where(classroom: classroom)).to be_empty
      end
    end

    context "with users from another school" do
      let!(:other_student) { create(:student) }
      before { school.start_sync }

      it "does not affect other schools' users" do
        expect(other_student.reload).not_to be_disabled
      end
    end
  end

  describe "#finish_sync" do
    let(:school) { create(:school, sync_status: :syncing) }

    it "sets sync_status to successful" do
      school.finish_sync
      expect(school.reload).to be_successful
    end

    context "with enrolled and unenrolled employees" do
      let!(:classroom) { create(:classroom, school: school) }
      let!(:enrolled_employee) { create(:teacher, school: school) }
      let!(:unenrolled_employee) { create(:teacher, school: school) }
      let!(:enrollment) { create(:enrollment, classroom: classroom, user: enrolled_employee) }
      before { school.finish_sync }

      it "disables unenrolled employees but not enrolled ones" do
        expect(unenrolled_employee.reload).to be_disabled
        expect(enrolled_employee.reload).not_to be_disabled
      end
    end

    context "with students" do
      let!(:student) { create(:student, school: school) }
      before { school.finish_sync }

      it "does not disable students" do
        expect(student.reload).not_to be_disabled
      end
    end
  end

  describe "#from_wonde" do
    let(:school) { described_class.from_wonde(OpenStruct.new(id: "1234", name: "test"), "token") }

    it "persists the school" do
      expect(school).to be_persisted
    end

    context "when a matching school already exists" do
      before { create(:school, client_id: "1234", name: "old name") }

      it "updates the existing school attributes" do
        expect(school).to have_attributes(client_id: "1234", name: "test")
      end
    end
  end
end
