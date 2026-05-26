# frozen_string_literal: true

require "rails_helper"

RSpec.describe ResetUserPasswordsJob, :default_creates do
  let!(:student) { create(:student, school: school) }

  describe "performing the job" do
    it "resets passwords for students of that school" do
      old_password = student.encrypted_password
      described_class.perform_now(school_admin)
      student.reload
      expect(student.encrypted_password).not_to eq(old_password)
    end

    it "resets passwords for employees" do
      old_password = teacher.encrypted_password
      described_class.perform_now(school_admin)
      teacher.reload
      expect(teacher.encrypted_password).not_to eq(old_password)
    end

    it "does not reset passwords for school admins" do
      old_password = school_admin.encrypted_password
      described_class.perform_now(school_admin)
      school_admin.reload
      expect(school_admin.encrypted_password).to eq(old_password)
    end

    it "resets passwords for the school belonging to the school admin only" do
      old_password = second_school_student.encrypted_password
      described_class.perform_now(school_admin)
      second_school_student.reload
      expect(second_school_student.encrypted_password).to eq(old_password)
    end

    context "when the student has previously signed in" do
      before { student.update!(sign_in_count: 1) }

      it "does not reset the password" do
        old_password = student.encrypted_password
        described_class.perform_now(school_admin)
        student.reload
        expect(student.encrypted_password).to eq(old_password)
      end
    end
  end
end
