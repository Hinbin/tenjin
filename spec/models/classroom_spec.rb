require 'rails_helper'

RSpec.describe Classroom, type: :model do
  it { is_expected.to validate_presence_of(:client_id) }
  it { is_expected.to validate_presence_of(:name) }

  describe 'validate uniqueness' do
    subject { create(:classroom) }

    it { is_expected.to validate_uniqueness_of(:client_id) }
  end

  describe '.classroom_from_client_id' do
    context 'when using the client_id' do
      it 'Finds the right classroom' do
        classroom = create(:classroom, client_id: 'ABCD')
        expect(Classroom.classroom_from_client_id('ABCD')).to eq(classroom)
      end
    end

    context 'when given a blank client_id' do
      it 'returns no records' do
        expect(Classroom.classroom_from_client_id(nil)).to eq(nil)
      end
    end
  end
end
