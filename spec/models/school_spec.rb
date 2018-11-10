require 'rails_helper'

RSpec.describe School, type: :model do
  it 'Adds a school to a database' do
    create(:school)
    expect(School.count).to eq(1)
  end
  it 'Does not alllow duplicate client IDs' do
    create(:school)
    expect { create(:school) }.to raise_error(ActiveRecord::RecordInvalid)
    expect(School.count).to eq(1)
  end
  it 'Does not allow a blank school name' do
    expect { create(:school, name: '') }.to raise_error(ActiveRecord::RecordInvalid)
  end
  it 'Does not allow a blank client id name' do
    expect { create(:school, clientID: '') }.to raise_error(ActiveRecord::RecordInvalid)
  end
end
