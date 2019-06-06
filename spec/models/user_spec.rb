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
      school_api_data
      create(:subject_map, client_subject_name: subject_api_data.data.name, school: School.first)
    end

    context 'with student api data' do
      it 'does not allow students missing a upi' do
        expect { create(:student, upi: nil) }.to raise_error(ActiveRecord::RecordInvalid)
      end
      it 'creates students who have a classroom for a mapped subject' do
        classroom_api_data[0].students = user_api_data
        User.from_wonde(school_api_data, classroom_api_data, school_api)
        expect(User.where(role: 'student').first.forename).to eq(user_api_data.data[0].forename)
      end

      it 'creates employees who have a classroom for a mapped subject' do
        classroom_api_data[0].employees = user_api_data
        allow(school_api).to receive_message_chain(:employees, :get).and_return(contact_details_api_data)
        User.from_wonde(school_api_data, classroom_api_data, school_api)
        expect(User.where(role: 'employee').first.forename).to eq(user_api_data.data[0].forename)
      end

      it 'only creates user accounts for those that need them' do
        classroom_data = classroom_api_data
        classroom_data[0].subject.data.name = 'Not a subject'
        User.from_wonde(school_api_data, classroom_api_data, school_api)
        expect(User.count).to eq(0)
      end

      it 'accepts both employee and student data' do
        classroom_api_data[0].students = user_api_data
        classroom_api_data[0].employees = alt_user_api_data
        allow(school_api).to receive_message_chain(:employees, :get).and_return(contact_details_api_data)
        User.from_wonde(school_api_data, classroom_api_data, school_api)
        expect(User.count).to eq(2)
      end

      it 'creates a username for a student' do
        classroom_api_data[0].students = user_api_data
        User.from_wonde(school_api_data, classroom_api_data, school_api)
        u = user_api_data.data[0]
        expect(User.first.username).to eq(u.forename[0].downcase + u.surname.downcase + u.upi[0..3])
      end

      it 'deals with duplicate user names' do
        classroom_api_data[0].students = duplicate_user_api_data
        User.from_wonde(school_api_data, classroom_api_data, school_api)
        u = duplicate_user_api_data.data[1]
        expect(User.second.username).to eq(u.forename[0].downcase + u.surname.downcase + u.upi[0..3] + '1')
      end

      it 'saves an employee e-mail' do
        classroom_api_data[0].employees = user_api_data
        allow(school_api).to receive_message_chain(:employees, :get).and_return(contact_details_api_data)
        User.from_wonde(school_api_data, classroom_api_data, school_api)
        expect(User.first.email).to eq(employee_email)
      end

      it 'does not create an employee record if no e-mail is supplied' do
        classroom_api_data[0].employees = user_api_data
        allow(school_api).to receive_message_chain(:employees, :get).and_return(contact_details_no_email_api_data)
        User.from_wonde(school_api_data, classroom_api_data, school_api)
        expect(User.count).to eq(0)
      end
    end
  end
end
