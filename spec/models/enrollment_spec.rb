# frozen_string_literal: true

require 'rails_helper'
require 'support/api_data'

RSpec.describe Enrollment, type: :model do
  let(:school) { create(:school, client_id: '1234') }

  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:classroom) }

  context 'with classroom and user data ' do
    let(:classrooms) { create_list(:classroom, 2, school: school) }
    let(:student) { create(:student, school: school) }

    before do
      create(:enrollment, classroom: classrooms[0], user: student)
    end

    it 'allows multiple classroom per user' do
      expect { create(:enrollment, classroom: classrooms[1], user: student) }.not_to raise_error
    end

    it 'validates uniqueness of user scoped to classroom' do
      expect { create(:enrollment, classroom: classrooms[0], user: student) }
        .to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe '#from_wonde' do
    include_context 'with api_data'

    before do
      school_api_data
      create(:classroom, client_id: 'classroom_id', school: School.first)
      create(:student, upi: user_api_data.data[0].upi, school: School.first)
      classroom_api_data.id = 'classroom_id'
    end

    context 'with api_data' do
      it 'creates student enrollments' do
        classroom_api_data.students = user_api_data
        described_class.from_wonde(classroom_api_data)
        expect(described_class.count).to eq(1)
      end

      it 'creates employee enrollments' do
        classroom_api_data.employees = user_api_data
        described_class.from_wonde(classroom_api_data)
        expect(described_class.count).to eq(1)
      end

      it 'enables classroom with enrollments' do
        classroom_api_data.employees = user_api_data
        described_class.from_wonde(classroom_api_data)
        expect(Classroom.first.disabled).to eq(false)
      end

      it 'handles null student and employee data' do
        described_class.from_wonde(classroom_api_data)
        expect(described_class.count).to eq(0)
      end
    end

    context 'when dealing with older data' do
      before do
        classroom_api_data.students = user_api_data
        School.from_wonde(school_api_data, classroom_api_data)
        described_class.from_wonde(classroom_api_data)
      end

      it 'removes old enrollments' do
        classroom_api_data.students = alt_user_api_data
        described_class.from_wonde(classroom_api_data)
        expect(described_class.count).to eq(0)
      end

      it 'disables classrooms with no enrollments' do
        classroom_api_data.students = alt_user_api_data
        described_class.from_wonde(classroom_api_data)
        expect(Classroom.first.disabled).to eq(true)
      end
    end
  end
end
