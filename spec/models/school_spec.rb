require 'rails_helper'

RSpec.describe School, type: :model do
  subject { create(:school) }

  it { is_expected.to validate_presence_of(:client_id) }
  it { is_expected.to validate_uniqueness_of(:client_id) }
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:token) }

  describe '#school_from_wonde' do
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

  describe '#school_from_client_id' do
    context 'with a school client id'
    it 'retrieves a school record' do
      school = create(:school)
      expect(School.school_from_client_id(school.client_id)) .to eq(school)
    end
  end
end
