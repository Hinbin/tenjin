# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserPolicy, :default_creates do
  subject(:policy) { described_class.new(actor, target) }

  let(:other_school) { create(:school) }

  describe "Scope" do
    subject(:resolved) { described_class::Scope.new(actor, User).resolve }

    let(:actor) { teacher }
    let!(:same_school_user) { create(:student, school: school) }
    let!(:other_school_user) { create(:student, school: other_school) }
    let!(:disabled_user) { create(:student, school: school, disabled: true) }

    it "includes users in the same school" do
      expect(resolved).to include(same_school_user)
    end

    it "excludes users in other schools" do
      expect(resolved).not_to include(other_school_user)
    end

    it "excludes disabled users in the same school" do
      expect(resolved).not_to include(disabled_user)
    end
  end

  describe "#index?" do
    let(:target) { build_stubbed(:student, school: school) }

    context "as a school admin" do
      let(:actor) { school_admin }
      it { is_expected.to be_index }
    end

    context "as a teacher" do
      let(:actor) { build_stubbed(:teacher, school: school) }
      it { is_expected.not_to be_index }
    end

    context "as a student" do
      let(:actor) { build_stubbed(:student, school: school) }
      it { is_expected.not_to be_index }
    end
  end

  describe "#show?" do
    context "as a school admin" do
      let(:actor) { school_admin }

      context "viewing a user in the same school" do
        let(:target) { build_stubbed(:student, school: school) }
        it { is_expected.to be_show }
      end

      context "viewing a user in another school" do
        let(:target) { build_stubbed(:student, school: other_school) }
        it { is_expected.not_to be_show }
      end
    end

    context "as a teacher" do
      let(:actor) { build_stubbed(:teacher, school: school) }

      context "viewing a student in the same school" do
        let(:target) { build_stubbed(:student, school: school) }
        it { is_expected.to be_show }
      end

      context "viewing a student in another school" do
        let(:target) { build_stubbed(:student, school: other_school) }
        it { is_expected.not_to be_show }
      end

      context "viewing another teacher in the same school" do
        let(:target) { build_stubbed(:teacher, school: school) }
        it { is_expected.not_to be_show }
      end

      context "viewing themselves" do
        let(:target) { actor }
        it { is_expected.to be_show }
      end
    end

    context "as a student" do
      let(:actor) { build_stubbed(:student, school: school) }

      context "viewing themselves" do
        let(:target) { actor }
        it { is_expected.to be_show }
      end

      context "viewing another student in the same school" do
        let(:target) { build_stubbed(:student, school: school) }
        it { is_expected.not_to be_show }
      end

      context "viewing a teacher in the same school" do
        let(:target) { build_stubbed(:teacher, school: school) }
        it { is_expected.not_to be_show }
      end
    end
  end

  describe "#update?" do
    context "as a teacher" do
      let(:actor) { build_stubbed(:teacher, school: school) }

      context "updating a user in the same school" do
        let(:target) { build_stubbed(:student, school: school) }
        it { is_expected.to be_update }
      end

      context "updating a user in another school" do
        let(:target) { build_stubbed(:student, school: other_school) }
        it { is_expected.not_to be_update }
      end
    end

    context "as a student" do
      let(:actor) { build_stubbed(:student, school: school) }

      context "updating themselves" do
        let(:target) { actor }
        it { is_expected.to be_update }
      end

      context "updating another student" do
        let(:target) { build_stubbed(:student, school: school) }
        it { is_expected.not_to be_update }
      end
    end
  end

  describe "#destroy?" do
    context "as a school admin" do
      let(:actor) { school_admin }

      context "destroying another user" do
        let(:target) { build_stubbed(:student, school: school) }
        it { is_expected.to be_destroy }
      end

      context "destroying themselves" do
        let(:target) { actor }
        it { is_expected.not_to be_destroy }
      end
    end

    context "as a teacher (without the school_admin role)" do
      let(:actor) { build_stubbed(:teacher, school: school) }
      let(:target) { build_stubbed(:student, school: school) }
      it { is_expected.not_to be_destroy }
    end

    context "as a student" do
      let(:actor) { build_stubbed(:student, school: school) }
      let(:target) { build_stubbed(:student, school: school) }
      it { is_expected.not_to be_destroy }
    end
  end

  describe "aliases" do
    let(:actor) { build_stubbed(:student, school: school) }
    let(:target) { actor }

    it "aliases #reset_password? to #show?" do
      expect(policy.reset_password?).to eq(policy.show?)
    end

    it "aliases #unlink_oauth_account? to #show?" do
      expect(policy.unlink_oauth_account?).to eq(policy.show?)
    end
  end
end
