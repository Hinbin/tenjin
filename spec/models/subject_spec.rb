require 'rails_helper'

RSpec.describe Subject, type: :model do
  context 'when creating a subject' do
    it 'prevents a subject with no name' do
      expect { create(:subject, name: nil) }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
