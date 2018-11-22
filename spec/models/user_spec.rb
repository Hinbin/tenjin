require 'rails_helper'
require 'support/api_data'

RSpec.describe User, type: :model do
  describe '#user_from_upi' do
    context 'with a upi' do
      let(:user) { create(:user, upi: '123456') }

      it 'retrieves the correct user record' do
        u = user
        expect(User.user_from_upi('123456')).to eq(u)
      end

      it 'returns nil when an invalid upi is given' do
        user
        expect(User.user_from_upi('56789')).to eq(nil)
      end
    end
  end

  describe '#from_wonde' do
    include_context 'api_data'

    before do
      school = create(:school, client_id: '1234')
      create(:subject_map, school: school)
    end

    context 'with student api data' do
      it 'does not allow students missing a upi' do
        expect { create(:student, upi: nil) }.to raise_error(ActiveRecord::RecordInvalid)
      end
      it 'creates students who have a classroom for a mapped subject' do
        classroom_api_data[0].students = user_api_data
        User.from_wonde(school_api_data, classroom_api_data)
        expect(User.where(role: 'student').first.forename).to eq('TestForename')
      end

      it 'creates employees who have a classroom for a mapped subject' do
        classroom_api_data[0].employees = user_api_data
        User.from_wonde(school_api_data, classroom_api_data)
        expect(User.where(role: 'employee').first.forename).to eq('TestForename')
      end

      it 'only creates user accounts for those that need them' do
        classroom_data = classroom_api_data
        classroom_data[0].subject.data.name = 'Not a subject'
        User.from_wonde(school_api_data, classroom_api_data)
        expect(User.count).to eq(0)
      end

      it 'accepts both employee and student data' do
        classroom_api_data[0].students = user_api_data
        classroom_api_data[0].employees = alt_user_api_data
        User.from_wonde(school_api_data, classroom_api_data)
        expect(User.count).to eq(2)
      end
    end
  end
end
