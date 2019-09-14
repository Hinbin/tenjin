require 'rails_helper'

RSpec.describe Subject, type: :model do
  subject { create(:subject) }

  it { is_expected.to validate_uniqueness_of(:name) }
  it { is_expected.to validate_presence_of(:name) }

end
