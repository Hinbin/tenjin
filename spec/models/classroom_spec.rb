require 'rails_helper'

RSpec.describe Classroom, type: :model do
  context 'when creating a classroom' do
    it 'must have a client ID' do
      expect { create(:classroom, client_id: nil) }.to raise_error ActiveRecord::RecordInvalid
    end

    it 'must have a name' do
      expect { create(:classroom, name: nil) }.to raise_error ActiveRecord::RecordInvalid
    end

    it 'Prevents duplicate client_ids' do
      create(:classroom)
      expect { create(:classroom) }.to raise_error ActiveRecord::RecordInvalid
    end
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