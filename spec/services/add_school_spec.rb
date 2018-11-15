require 'rails_helper'

RSpec.describe AddSchool, '#new' do
  it 'Create a Wonde API school object', :vcr do
    @add_school = AddSchool.new('2a550dc912f6a63488af42352b79c5961e87daf9', 'A852030759')
    expect(@add_school).not_to be_blank
  end
end
# rubocop:disable Metrics/BlockLength
RSpec.describe AddSchool, '#call' do
  def update_school_from_wonde
    add_school = AddSchool.new('2a550dc912f6a63488af42352b79c5961e87daf9', 'A852030759')
    add_school.call
  end

  def school_in_db
    School.find_by(name: 'Outwood Grange Academy 1532082212')
  end

  context 'when using wonde api data' do
    before do
      update_school_from_wonde
    end

    it 'creates a school', :vcr do
      expect(school_in_db.name).to eq 'Outwood Grange Academy 1532082212'
    end
    it 'adds a permitted school entry', :vcr do
      expect(PermittedSchool.first.name).to eq 'Outwood Grange Academy 1532082212'
    end
  end

  context 'when given updated school data' do
    it 'updates a school name', :vcr do
      create(:school, name: 'Not outwood', client_id: 'A852030759')
      update_school_from_wonde
      school_found = school_in_db
      expect(School.count).to eq(1)
      expect(school_found.name).to eq 'Outwood Grange Academy 1532082212'
    end
  end
end

# rubocop:enable Metrics/BlockLength
