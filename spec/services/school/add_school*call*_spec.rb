require 'rails_helper'

RSpec.describe School::AddSchool, '#call' do
  let(:school_token) { '2a550dc912f6a63488af42352b79c5961e87daf9' }
  let(:school_id) { 'A852030759' }
  let(:school_params) { ActionController::Parameters.new(token: school_token, client_id: school_id) }

  def update_school_from_wonde
    School::AddSchool.new(school_params).call
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

  end

  context 'when given updated school data' do
    before do
      create(:school, name: 'Not outwood', client_id: 'A852030759')
    end

    it 'updates a school name', :vcr do
      update_school_from_wonde
      expect(School.first.name).to eq 'Outwood Grange Academy 1532082212'
    end

    it 'does not create a duplicate school', :vcr do
      update_school_from_wonde
      expect(School.count).to eq(1)
    end
  end
end
