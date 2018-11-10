require 'rails_helper'

RSpec.describe FullySynchroniseSchool, '#new' do
  it 'Create a Wonde API school object', :vcr do
    @sync_school = FullySynchroniseSchool.new('2a550dc912f6a63488af42352b79c5961e87daf9', 'A852030759')
    expect(@sync_school).not_to be_blank
  end
end

RSpec.describe FullySynchroniseSchool, '#call' do
  def school_from_wonde
    @sync_school = FullySynchroniseSchool.new('2a550dc912f6a63488af42352b79c5961e87daf9', 'A852030759')
    @sync_school.call
  end

  def school_in_db
    School.find_by(name: 'Outwood Grange Academy 1532082212')
  end

  it 'Retreieves a Wonde School object', :vcr do
      expect(school_from_wonde.name).to eq 'Outwood Grange Academy 1532082212'
  end
  it 'Enters the school into the database', :vcr do
    school_from_wonde
    expect(school_in_db.name).to eq 'Outwood Grange Academy 1532082212'
  end
  it 'Detects if the school name has changed', :vcr, focus: true do
    create(:school, name: 'Not outwood')
    school_from_wonde
    school_found = school_in_db
    expect(School.count).to eq(1)
    expect(school_found.name).to eq 'Outwood Grange Academy 1532082212'
  end
end
