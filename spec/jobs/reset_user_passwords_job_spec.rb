# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ResetUserPasswordsJob do
  context 'when resetting the passwords for the whole school', :default_creates do
    let(:reset_password) { Quiz::CreateQuiz.new(admin: school_admin).call }

    before do
      student
    end

    it 'resets passwords for students of that school' do
      old_password = student.encrypted_password
      described_class.perform_now(school_admin)
      student.reload
      expect(student.encrypted_password).not_to eq(old_password)
    end

    it 'resets passwords for employees' do
      old_password = teacher.encrypted_password
      described_class.perform_now(school_admin)
      teacher.reload
      expect(teacher.encrypted_password).not_to eq(old_password)
    end

    it 'does not reset passwords for school admins' do
      old_password = school_admin.encrypted_password
      described_class.perform_now(school_admin)
      school_admin.reload
      expect(school_admin.encrypted_password).to eq(old_password)
    end

    it 'resets passwords for the school belonging to the school admin only' do
      old_password = second_school_student.encrypted_password
      described_class.perform_now(school_admin)
      second_school_student.reload
      expect(second_school_student.encrypted_password).to eq(old_password)
    end

    it 'does not reset passwords for users who have logged in previously' do
      student.update_attribute('sign_in_count', 1)
      old_password = student.encrypted_password
      described_class.perform_now(school_admin)
      student.reload
      expect(student.encrypted_password).to eq(old_password)
    end
  end
end
