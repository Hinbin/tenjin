# frozen_string_literal: true

require "rails_helper"

RSpec.describe System::UserPolicy, :default_creates do
  subject(:policy) { described_class.new(actor, target_user) }

  let(:target_user) { create(:teacher, school: school) }

  describe "#become?" do
    context "as a super admin" do
      let(:actor) { build_stubbed(:super_admin) }
      it { is_expected.to be_become }
    end

    context "as a school group admin" do
      let(:actor) { build_stubbed(:school_group_admin) }
      it { is_expected.to be_become }
    end
  end

  describe "#set_role?" do
    context "as a super admin against an employee" do
      let(:actor) { build_stubbed(:super_admin) }
      let(:target_user) { create(:teacher, school: school) }
      it { is_expected.to be_set_role }
    end

    context "as a super admin against a student" do
      let(:actor) { build_stubbed(:super_admin) }
      let(:target_user) { create(:student, school: school) }
      it { is_expected.not_to be_set_role }
    end

    context "as a school group admin against an employee" do
      let(:actor) { build_stubbed(:school_group_admin) }
      let(:target_user) { create(:teacher, school: school) }
      it { is_expected.not_to be_set_role }
    end
  end

  describe "#remove_role?" do
    context "as a super admin against an employee" do
      let(:actor) { build_stubbed(:super_admin) }
      let(:target_user) { create(:teacher, school: school) }
      it { is_expected.to be_remove_role }
    end

    context "as a school group admin against an employee" do
      let(:actor) { build_stubbed(:school_group_admin) }
      let(:target_user) { create(:teacher, school: school) }
      it { is_expected.not_to be_remove_role }
    end
  end

  describe "#update_email?" do
    context "as a super admin against an employee" do
      let(:actor) { build_stubbed(:super_admin) }
      let(:target_user) { create(:teacher, school: school) }
      it { is_expected.to be_update_email }
    end

    context "as a school group admin against an employee" do
      let(:actor) { build_stubbed(:school_group_admin) }
      let(:target_user) { create(:teacher, school: school) }
      it { is_expected.not_to be_update_email }
    end
  end

  describe "#send_welcome_email?" do
    context "as a super admin against an employee" do
      let(:actor) { build_stubbed(:super_admin) }
      let(:target_user) { create(:teacher, school: school) }
      it { is_expected.to be_send_welcome_email }
    end

    context "as a school group admin against an employee" do
      let(:actor) { build_stubbed(:school_group_admin) }
      let(:target_user) { create(:teacher, school: school) }
      it { is_expected.not_to be_send_welcome_email }
    end
  end
end
