require 'rails_helper'

RSpec.describe School, type: :model do
  context 'with school data' do
    it 'Adds a school to a database' do
      create(:school)
      expect(School.count).to eq(1)
    end
    it 'Does not alllow duplicate client IDs' do
      create(:school)
      expect { create(:school) }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  it 'Does not allow a blank school name' do
    expect { create(:school, name: '') }.to raise_error(ActiveRecord::RecordInvalid)
  end
  it 'Does not allow a blank client id name' do
    expect { create(:school, client_id: '') }.to raise_error(ActiveRecord::RecordInvalid)
  end

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
end
