# frozen_string_literal: true

require "rails_helper"

RSpec.describe System::CustomisationPolicy do
  subject(:policy) { described_class.new(actor, Customisation.new) }

  shared_examples "permitted only for super admins" do |action|
    context "as a super admin" do
      let(:actor) { build_stubbed(:super_admin) }
      it { is_expected.to public_send(:"be_#{action}") }
    end

    context "as a school group admin" do
      let(:actor) { build_stubbed(:school_group_admin) }
      it { is_expected.not_to public_send(:"be_#{action}") }
    end
  end

  describe "#index?" do
    include_examples "permitted only for super admins", :index
  end

  describe "#show?" do
    include_examples "permitted only for super admins", :show
  end

  describe "#new?" do
    include_examples "permitted only for super admins", :new
  end

  describe "#create?" do
    include_examples "permitted only for super admins", :create
  end

  describe "#edit?" do
    include_examples "permitted only for super admins", :edit
  end

  describe "#update?" do
    include_examples "permitted only for super admins", :update
  end

  describe "Scope" do
    subject(:resolved) { described_class::Scope.new(actor, Customisation).resolve }

    let!(:customisation) { create(:customisation) }

    context "as a super admin" do
      let(:actor) { build_stubbed(:super_admin) }
      it { is_expected.to include(customisation) }
    end

    context "as a school group admin" do
      let(:actor) { build_stubbed(:school_group_admin) }
      it { is_expected.to be_nil }
    end
  end
end
