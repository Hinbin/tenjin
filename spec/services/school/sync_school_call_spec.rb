# frozen_string_literal: true

require "rails_helper"

RSpec.describe School::SyncSchool, :vcr do
  include ActiveJob::TestHelper

  include_context "with api_data"
  include_context "with wonde_test_data"

  let(:sociology_class) { Classroom.find_by(client_id: classroom_client_id) }

  def sync_school_with_wonde
    school = School::AddSchool.call(school_params)
    perform_enqueued_jobs do
      SyncSchoolJob.perform_later school
    end
  end

  context "with classroom data" do
    before do
      sync_school_with_wonde
    end

    it "creates classrooms" do
      expect(Classroom.count).to be_positive
    end

    it "creates classrooms with the correct client id" do
      expect(Classroom.find_by(client_id: classroom_client_id)).to have_attributes(name: classroom_name)
    end

    it "creates classrooms for the correct school" do
      expect(sociology_class.school).to have_attributes(client_id: school_id)
    end

    context "when the classroom has a subject assigned" do
      before do
        sociology_class.update!(subject: create(:subject))
        sync_school_with_wonde
      end

      it "enrolls students into the classroom" do
        expect(sociology_class.reload.enrollments).not_to be_empty
      end

      context "when synced multiple times" do
        before do
          sync_school_with_wonde
        end

        it "does not duplicate enrollments" do
          expect(Enrollment.where(user: User.find_by!(upi: student_upi)).count).to eq(1)
        end
      end
    end

    context "when a classroom no longer exists in the MIS" do
      before do
        create(:classroom, school: School.find_by!(client_id: school_id), client_id: "1234")
        sync_school_with_wonde
      end

      it "disables classrooms that no longer exist in the MIS" do
        expect(Classroom.find_by(client_id: "1234")).to be_disabled
      end
    end
  end

  context "when receiving updated classroom data" do
    let(:existing_school) { create(:school, client_id: school_id) }
    let!(:existing_classroom) { create(:classroom, client_id: classroom_client_id, school: existing_school) }

    context "when synced with new data" do
      before { sync_school_with_wonde }

      it "updates the classroom name" do
        expect(Classroom.find_by!(client_id: classroom_client_id).name).to eq classroom_name
      end
    end

    context "when a student enrollment no longer exists in the MIS" do
      let(:student) { create(:student, upi: "1234") }

      before do
        create(:enrollment, classroom: existing_classroom, user: student)
        sync_school_with_wonde
      end

      it "removes enrollments that no longer exist in the MIS" do
        expect(Enrollment.where(user: student)).to be_empty
      end
    end
  end

  context "with student data" do
    before do
      sync_school_with_wonde
      sociology_class.update!(subject: create(:subject))
      sync_school_with_wonde
    end

    it "creates student entries" do
      expect(User.where(role: "student")).not_to be_empty
    end

    it "creates employee entries" do
      expect(User.where(role: "employee")).not_to be_empty
    end

    it "links each student to the correct school" do
      expect(User.find_by!(upi: student_upi).school.name).to eq(school_name)
    end
  end

  context "when given updated student data" do
    context "when student details have changed in the MIS" do
      before do
        create(:student, forename: "test", upi: student_upi)
        sync_school_with_wonde
        sociology_class.update!(subject: create(:subject))
        sync_school_with_wonde
      end

      it "updates student details" do
        expect(User.find_by(upi: student_upi).forename).to eq(student_forename)
      end
    end

    context "when the student has existing challenge points" do
      let!(:student_with_points) { create(:student, upi: student_upi, challenge_points: 50) }

      before do
        sync_school_with_wonde
      end

      it "preserves the student's challenge points" do
        expect(User.find_by(upi: student_upi).challenge_points).to eq(50)
      end
    end
  end

  context "with a new teacher assigned to a classroom" do
    before do
      school = create(:school, client_id: school_id)
      classroom = create(:classroom, client_id: classroom_client_id, school: school)
      employee = create(:user, role: "employee")
      create(:enrollment, classroom: classroom, user: employee)
      sync_school_with_wonde
    end

    it "updates the classroom owner to the current employee" do
      expect(Classroom.find_by(client_id: classroom_client_id).users
        .find_by(role: "employee").upi).to eq(employee_upi)
    end
  end

  context "with updated employee data" do
    before do
      create(:teacher, upi: employee_upi)
      sync_school_with_wonde
      sociology_class.update!(subject: create(:subject))
      sync_school_with_wonde
    end

    it "updates employee details" do
      expect(User.find_by(upi: employee_upi).forename).to eq(employee_name)
    end
  end
end
