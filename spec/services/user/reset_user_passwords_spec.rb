# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User::ResetUserPasswords do
  context 'when resetting the passwords for the whole school', default_creates: true do
    let(:reset_password) { Quiz::CreateQuiz.new(admin: school_admin).call }

    before do
      student
    end

    it 'resets passwords for students of that school' do
      old_password = student.encrypted_password
      described_class.new(school_admin).call
      student.reload
      expect(student.encrypted_password).not_to eq(old_password)
    end

    it 'reveals the new password for each user after a reset' do
      result = described_class.new(school_admin).call
      expect(result.user_data[student.upi]).not_to be_empty
    end

    it 'resets passwords for multiple users of school' do
      create_list(:student, 19, school: school)
      result = described_class.new(school_admin).call
      expect(result.user_data.count).to eq(20)
    end

    it 'returns unsuccessfully if there are no students' do
      User.where(role: 'student').destroy_all
      result = described_class.new(school_admin).call
      expect(result.success?).to eq(false)
    end

    it 'returns unsuccessfully if no admin is supplied' do
      result = described_class.new(nil).call
      expect(result.success?).to eq(false)
    end

    it 'resets passwords for employees' do
      old_password = teacher.encrypted_password
      described_class.new(school_admin).call
      teacher.reload
      expect(teacher.encrypted_password).not_to eq(old_password)
    end

    it 'does not reset passwords for school admins' do
      old_password = school_admin.encrypted_password
      described_class.new(school_admin).call
      school_admin.reload
      expect(school_admin.encrypted_password).to eq(old_password)
    end

    it 'resets passwords for the school belonging to the school admin only' do
      old_password = second_school_student.encrypted_password
      described_class.new(school_admin).call
      second_school_student.reload
      expect(second_school_student.encrypted_password).to eq(old_password)
    end

    it 'reports success if all passwords have been changed' do
      create_list(:student, 19, school: school)
      result = described_class.new(school_admin).call
      expect(result.success?).to eq(true)
    end

    it 'returns a list of usernames and passwords' do
      create_list(:student, 19, school: school)
      result = described_class.new(school_admin).call
      expect(result.user_data).to be_present
    end

    it 'does not reset passwords for users who have logged in previously' do
      student.update_attribute('sign_in_count', 1)
      old_password = student.encrypted_password
      described_class.new(school_admin).call
      student.reload
      expect(student.encrypted_password).to eq(old_password)
    end
  end
end
