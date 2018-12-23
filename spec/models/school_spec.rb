require 'rails_helper'
require 'support/api_data'

RSpec.describe School, type: :model do
  include_context 'api_data'
  subject { create(:school) }

  it { is_expected.to validate_presence_of(:client_id) }
  it { is_expected.to validate_uniqueness_of(:client_id) }
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:token) }

  describe '#from_wonde' do
    let(:school) { School.from_wonde(OpenStruct.new(id: '1234', name: 'test'), 'token') }

    it 'Adds a school from a wonde object' do
      expect(school.persisted?).to be true
    end

    it 'Updates a school from a wonde object' do
      create(:school, id: '1234', name: 'old name')
      school
      expect(school).to have_attributes(client_id: '1234', name: 'test')
    end
  end

  describe 'from_wonde_sync_start' do
    it 'removes old enrollments' do
      classroom_api_data[0].students = user_api_data
      School.from_wonde(school_api_data, classroom_api_data)
      classroom_api_data[0].students = alt_user_api_data
      Enrollment.from_wonde(school_api_data, classroom_api_data)
      expect(Enrollment.count).to eq(0)
    end

    it 'disables old classrooms'
  end

  describe '#school_from_client_id' do
    context 'with a school client id'
    it 'retrieves a school record' do
      school = create(:school)
      expect(School.school_from_client_id(school.client_id)) .to eq(school)
    end
  end
end
