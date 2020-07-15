# frozen_string_literal: true

require 'rails_helper'
require 'support/api_data'

RSpec.describe User, type: :model do
  describe '#from_wonde' do
    include_context 'with api_data'

    let(:classroom) { create(:classroom) }

    before do
      school_api_data
    end

    context 'with student api data' do
      it 'does not allow students missing a upi' do
        expect { create(:student, upi: '') }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it 'creates students who have a classroom for a mapped subject' do
        classroom_api_data.students = user_api_data
        described_class.from_wonde(school_api_data, classroom_api_data, classroom)
        expect(described_class.where(role: 'student').first.forename).to eq(user_api_data.data[0].forename)
      end

      it 'creates employees who have a classroom for a mapped subject' do
        classroom_api_data.employees = user_api_data
        allow(school_api).to receive(:get).and_return(contact_details_api_data)
        described_class.from_wonde(school_api_data, classroom_api_data, classroom)
        expect(described_class.where(role: 'employee').first.forename).to eq(user_api_data.data[0].forename)
      end

      it 'only creates user accounts for those that need them' do
        classroom_data = classroom_api_data
        classroom_data.subject.data.name = 'Not a subject'
        described_class.from_wonde(school_api_data, classroom_api_data, classroom)
        expect(described_class.count).to eq(0)
      end

      it 'accepts both employee and student data' do
        classroom_api_data.students = user_api_data
        classroom_api_data.employees = alt_user_api_data
        allow(school_api).to receive(:get).and_return(contact_details_api_data)
        described_class.from_wonde(school_api_data, classroom_api_data, classroom)
        expect(described_class.count).to eq(2)
      end

      it 'creates a username for a student' do
        classroom_api_data.students = user_api_data
        described_class.from_wonde(school_api_data, classroom_api_data, classroom)
        u = user_api_data.data[0]
        expect(described_class.first.username).to eq(u.forename[0].downcase + u.surname.downcase + u.upi[0..3])
      end

      it 'deals with duplicate user names' do
        classroom_api_data.students = duplicate_user_api_data
        described_class.from_wonde(school_api_data, classroom_api_data, classroom)
        u = duplicate_user_api_data.data[1]
        expect(described_class.second.username)
          .to start_with(u.forename[0].downcase + u.surname.downcase)
      end

      it 'does not update a username if the record already exists' do
        described_class.create(upi: user_api_data.upi, username: 'test')
        classroom_api_data.employees = user_api_data
        allow(school_api).to receive(:get).and_return(contact_details_api_data)
        described_class.from_wonde(school_api_data, classroom_api_data, classroom)
        described_class.first.username = 'test'
      end
    end
  end
end
