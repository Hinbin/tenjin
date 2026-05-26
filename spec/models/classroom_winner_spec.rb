# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClassroomWinner do
  let(:different_schools) { build(:classroom_winner, user: create(:student), classroom: create(:classroom)) }
  let(:school) { create(:school) }
  let(:same_school) do
    build(:classroom_winner, user: create(:student, school: school),
      classroom: create(:classroom, school: school))
  end

  it "has a valid factory" do
    expect(build(:classroom_winner)).to be_valid
  end

  it "raises when user and classroom schools differ" do
    expect { different_schools.save! }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it "accepts a valid record" do
    expect(same_school).to be_valid
  end
end
