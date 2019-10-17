# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ClassroomWinner, type: :model do
  let(:different_schools) { build(:classroom_winner, user: create(:student), classroom: create(:classroom)) }
  let(:school) { create(:school) }
  let(:same_school) { build(:classroom_winner, user: create(:student, school: school), classroom: create(:classroom, school: school)) }

  it 'validates the user and classroom belong to the same school' do
    expect { different_schools.save! }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it 'accepts a valid record' do
    expect(same_school).to be_valid
  end
end
