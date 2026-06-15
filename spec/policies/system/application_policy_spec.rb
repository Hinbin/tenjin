# frozen_string_literal: true

require "rails_helper"

RSpec.describe System::ApplicationPolicy do
  subject(:policy) { described_class.new(admin, record) }

  let(:admin) { build_stubbed(:super_admin) }
  let(:record) { Object.new }

  describe "default predicates" do
    it { is_expected.not_to be_index }
    it { is_expected.not_to be_show }
    it { is_expected.not_to be_create }
    it { is_expected.not_to be_new }
    it { is_expected.not_to be_update }
    it { is_expected.not_to be_edit }
    it { is_expected.not_to be_destroy }
  end

  describe "accessors" do
    it "exposes the admin as #admin" do
      expect(policy.admin).to eq(admin)
    end

    it "aliases #user to the admin for Pundit compatibility" do
      expect(policy.user).to eq(admin)
    end

    it "exposes the record as #record" do
      expect(policy.record).to eq(record)
    end
  end

  describe "role predicate helpers" do
    let(:helper_policy_class) do
      Class.new(described_class) do
        def can_super? = super?
        def can_school_group? = school_group?
      end
    end

    subject(:helper_policy) { helper_policy_class.new(admin, record) }

    context "as a super admin" do
      let(:admin) { build_stubbed(:super_admin) }

      it { is_expected.to be_can_super }
      it { is_expected.not_to be_can_school_group }
    end

    context "as a school group admin" do
      let(:admin) { build_stubbed(:school_group_admin) }

      it { is_expected.not_to be_can_super }
      it { is_expected.to be_can_school_group }
    end
  end

  describe described_class::Scope do
    subject(:scope) { described_class.new(admin, Object) }

    it "exposes the admin" do
      expect(scope.send(:admin)).to eq(admin)
    end

    it "aliases #user to the admin" do
      expect(scope.send(:user)).to eq(admin)
    end

    it "raises NoMethodError on #resolve to force subclasses to implement it" do
      expect { scope.resolve }.to raise_error(NoMethodError, /must implement #resolve/)
    end

    describe "role predicate helpers" do
      let(:helper_scope_class) do
        Class.new(described_class) do
          def resolve = {super: super?, school_group: school_group?}
        end
      end

      subject(:helper_scope) { helper_scope_class.new(admin, Object) }

      context "as a super admin" do
        let(:admin) { build_stubbed(:super_admin) }

        it { expect(helper_scope.resolve).to eq(super: true, school_group: false) }
      end

      context "as a school group admin" do
        let(:admin) { build_stubbed(:school_group_admin) }

        it { expect(helper_scope.resolve).to eq(super: false, school_group: true) }
      end
    end
  end
end
