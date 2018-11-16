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
  it 'Adds a school from a wonde object'
  it 'Updates a school from a wonde object'
end
