# frozen_string_literal: true

require "rails_helper"

RSpec.describe SchoolPolicy, :default_creates do
  subject(:policy) { described_class.new(actor, school) }

  describe "#reset_all_passwords?" do
    context "as a school admin of the school" do
      let(:actor) { school_admin }
      it { is_expected.to be_reset_all_passwords }
    end

    context "as a school admin of another school" do
      let(:actor) { create(:school_admin, school: create(:school)) }
      it { is_expected.not_to be_reset_all_passwords }
    end

    context "as a student" do
      let(:actor) { student }
      it { is_expected.not_to be_reset_all_passwords }
    end
  end

  describe "#sync?" do
    context "as a school admin of the school" do
      let(:actor) { school_admin }
      it { is_expected.to be_sync }
    end

    context "as a school admin of another school" do
      let(:actor) { create(:school_admin, school: create(:school)) }
      it { is_expected.not_to be_sync }
    end

    context "as a student" do
      let(:actor) { student }
      it { is_expected.not_to be_sync }
    end
  end
end
