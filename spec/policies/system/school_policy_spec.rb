# frozen_string_literal: true

require "rails_helper"

RSpec.describe System::SchoolPolicy, :default_creates do
  subject(:policy) { described_class.new(actor, school) }

  describe "#show?" do
    context "as a super admin" do
      let(:actor) { build_stubbed(:super_admin) }
      it { is_expected.to be_show }
    end

    context "as a school group admin" do
      let(:actor) { build_stubbed(:school_group_admin) }
      it { is_expected.to be_show }
    end
  end

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

  describe "#sync?" do
    context "as a super admin" do
      let(:actor) { build_stubbed(:super_admin) }
      it { is_expected.to be_sync }
    end

    context "as a school group admin" do
      let(:actor) { build_stubbed(:school_group_admin) }
      it { is_expected.not_to be_sync }
    end
  end

  describe "Scope" do
    subject(:resolved) { described_class::Scope.new(actor, School).resolve }

    let!(:another_school) { create(:school) }

    context "as a super admin" do
      let(:actor) { build_stubbed(:super_admin) }

      it "includes every school" do
        expect(resolved).to include(school, another_school)
      end
    end
  end
end
