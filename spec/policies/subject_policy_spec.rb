# frozen_string_literal: true

require "rails_helper"

RSpec.describe SubjectPolicy, :default_creates do
  subject(:policy) { described_class.new(actor, quiz_subject) }

  describe "#new?" do
    context "as a super admin" do
      let(:actor) { build_stubbed(:super_admin) }
      it { is_expected.to be_new }
    end

    context "as a school group admin" do
      let(:actor) { build_stubbed(:school_group_admin) }
      it { is_expected.not_to be_new }
    end
  end
end
