# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClassroomPolicy, :default_creates do
  subject(:policy) { described_class.new(actor, classroom) }

  describe "#show?" do
    context "as a teacher" do
      let(:actor) { teacher }
      it { is_expected.to be_show }
    end

    context "as a student" do
      let(:actor) { student }
      it { is_expected.not_to be_show }
    end
  end
end
