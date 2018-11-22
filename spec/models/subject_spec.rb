require 'rails_helper'

RSpec.describe Subject, type: :model do
  context 'when creating a subject' do
    it 'prevents a subject with no name' do
      expect { create(:subject, name: nil) }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe '#subjects_for_school' do
    context 'with a school object' do
      let(:school) { create(:school) }
      let(:subject_taught) { create(:subject) }

      it 'Returns subjects for a school' do
        create(:subject_map, school: school)
        expect(Subject.subjects_for_school(school).count).to eq(1)
      end

      it 'Does not allow duplicates for a subject' do
        create(:subject_map, school: school, subject: subject_taught)
        create(:subject_map, client_id: 'secondmap', school: school, subject: subject_taught)
        expect(Subject.subjects_for_school(school).count).to eq(1)
      end

      it 'Only returns subjects for the correct school' do
        school2 = create(:school, client_id: 'school two')
        subject2 = create(:subject, name: 'another subject')
        create(:subject_map, school: school, subject: subject_taught)
        create(:subject_map, client_id: 'secondmap', school: school2, subject: subject2)
        expect(Subject.subjects_for_school(school).first).to eq(subject_taught)
      end
    end
  end
end
