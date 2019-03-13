require 'rails_helper'

RSpec.describe DefaultSubjectMap, type: :model do
  it { is_expected.to validate_presence_of(:name)}
  it { is_expected.to belong_to(:subject)}
  it 'works with the latest version of shoulda matchers'
end
