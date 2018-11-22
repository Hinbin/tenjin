require 'rails_helper'
require 'support/api_data'

RSpec.describe SubjectMap, type: :model do
  include_context 'api_data'

  it { is_expected.to validate_presence_of(:client_id) }
  it { is_expected.to validate_uniqueness_of(:client_id) }
  it { is_expected.to validate_presence_of(:client_subject_name) }
  it { is_expected.to belong_to(:school) }

  describe '#from_wonde' do
    let (:subject_map_record) { SubjectMap.from_wonde(create(:school), [subject_api_data.data]) }

    it 'creates subject maps from api data' do
      expect { subject_map_record }.to change(SubjectMap, :count)
    end

    it 'Uses default subject maps' do
      default_map = create(:default_subject_map)
      subject_map_record
      expect(SubjectMap.first.subject).to eq(default_map.subject)
    end

    it 'Sets subject maps without a correct default subject association to nil' do
      subject_map_record
      expect(SubjectMap.first.subject).to eq(nil)
    end
  end

  describe '#subject_maps_from_school' do
    context 'with a school record' do
      let(:school) { create(:school) }

      it 'only return the subject maps for that school' do
        create(:subject_map, school: school)
        school2 = create(:school, client_id: 'second school')
        create(:subject_map, client_id: 'second subject map', school: school2)
        expect(SubjectMap.subject_maps_for_school(school).count).to eq(1)
      end
    end
  end
end
