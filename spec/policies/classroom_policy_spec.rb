# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ClassroomPolicy do
  subject(:policy) { described_class.new(user, classroom) }

  let(:school) { create(:school) }
  let(:classroom) { create(:classroom, school: school) }

  describe '#gaps?' do
    context 'with a teacher from the same school' do
      let(:user) { create(:teacher, school: school) }

      it { expect(policy.gaps?).to be(true) }
    end

    context 'with a teacher from another school' do
      let(:user) { create(:teacher) }

      it { expect(policy.gaps?).to be(false) }
    end

    context 'with a student in the school' do
      let(:user) { create(:student, school: school) }

      it { expect(policy.gaps?).to be(false) }
    end
  end
end
