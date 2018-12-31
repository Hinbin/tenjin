require 'rails_helper'

RSpec.describe Multiplier, type: :model do
  it { is_expected.to validate_presence_of(:score) }
  it { is_expected.to validate_uniqueness_of(:score) }
  it { is_expected.to validate_presence_of(:multiplier) }
end
