# frozen_string_literal: true

require "rails_helper"

RSpec.describe System::AdminPolicy do
  subject(:policy) { described_class.new(admin, admin) }

  describe "#show?" do
    context "as a super admin" do
      let(:admin) { build_stubbed(:super_admin) }
      it { is_expected.to be_show }
    end

    context "as a school group admin" do
      let(:admin) { build_stubbed(:school_group_admin) }
      it { is_expected.not_to be_show }
    end
  end

  describe "#new?" do
    context "as a super admin" do
      let(:admin) { build_stubbed(:super_admin) }
      it { is_expected.to be_new }
    end

    context "as a school group admin" do
      let(:admin) { build_stubbed(:school_group_admin) }
      it { is_expected.not_to be_new }
    end
  end

  describe "#manage_roles?" do
    context "as a super admin" do
      let(:admin) { build_stubbed(:super_admin) }
      it { is_expected.to be_manage_roles }
    end

    context "as a school group admin" do
      let(:admin) { build_stubbed(:school_group_admin) }
      it { is_expected.not_to be_manage_roles }
    end
  end

  describe "#reset_year?" do
    context "as a super admin" do
      let(:admin) { build_stubbed(:super_admin) }
      it { is_expected.to be_reset_year }
    end

    context "as a school group admin" do
      let(:admin) { build_stubbed(:school_group_admin) }
      it { is_expected.not_to be_reset_year }
    end
  end

  describe "#show_stats?" do
    context "as a super admin" do
      let(:admin) { build_stubbed(:super_admin) }
      it { is_expected.to be_show_stats }
    end

    context "as a school group admin" do
      let(:admin) { build_stubbed(:school_group_admin) }
      it { is_expected.to be_show_stats }
    end
  end
end
