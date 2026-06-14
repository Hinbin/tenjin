# frozen_string_literal: true

require "rails_helper"

RSpec.describe System::SchoolGroupPolicy, :default_creates do
  subject(:policy) { described_class.new(actor, school_group) }

  let(:school_group) { create(:school_group) }

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

  describe "#create?" do
    context "as a super admin" do
      let(:actor) { build_stubbed(:super_admin) }
      it { is_expected.to be_create }
    end

    context "as a school group admin" do
      let(:actor) { build_stubbed(:school_group_admin) }
      it { is_expected.not_to be_create }
    end
  end

  describe "#update?" do
    context "as a super admin" do
      let(:actor) { build_stubbed(:super_admin) }
      it { is_expected.to be_update }
    end

    context "as a school group admin" do
      let(:actor) { build_stubbed(:school_group_admin) }
      it { is_expected.not_to be_update }
    end
  end

  describe "#destroy?" do
    context "as a super admin" do
      let(:actor) { build_stubbed(:super_admin) }
      it { is_expected.to be_destroy }
    end

    context "as a school group admin" do
      let(:actor) { build_stubbed(:school_group_admin) }
      it { is_expected.not_to be_destroy }
    end
  end

  describe "Scope" do
    subject(:resolved) { described_class::Scope.new(actor, SchoolGroup).resolve }

    let!(:another_school_group) { create(:school_group) }

    context "as a super admin" do
      let(:actor) { build_stubbed(:super_admin) }

      it "includes every school group" do
        expect(resolved).to include(school_group, another_school_group)
      end
    end

    context "as a school group admin" do
      let(:actor) { build_stubbed(:school_group_admin) }

      it "includes every school group" do
        expect(resolved).to include(school_group, another_school_group)
      end
    end
  end
end
