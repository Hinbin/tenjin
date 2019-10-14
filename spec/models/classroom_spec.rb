require 'rails_helper'

RSpec.describe Classroom, type: :model do
  it { is_expected.to validate_presence_of(:client_id) }
  it { is_expected.to validate_presence_of(:name) }

  describe 'validate uniqueness' do
    subject { create(:classroom) }

    it { is_expected.to validate_uniqueness_of(:client_id) }
  end
end
