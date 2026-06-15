# frozen_string_literal: true

require "rails_helper"

RSpec.describe User::ChangeUserRole, :default_creates do
  let(:teacher) { create(:teacher, school: school) }

  describe "validation failures" do
    it "fails when user is nil" do
      result = described_class.call(user: nil, role: "school_admin", action: :add)
      expect(result).to be_failure
      expect(result.error).to eq "User not found"
    end

    it "fails when role is nil" do
      result = described_class.call(user: teacher, role: nil, action: :add)
      expect(result).to be_failure
      expect(result.error).to eq "Role not found"
    end

    it "fails when action is not :add or :remove" do
      result = described_class.call(user: teacher, role: "school_admin", action: :sideways)
      expect(result).to be_failure
      expect(result.error).to eq 'Action must be "add" or "remove"'
    end

    it "fails when subject is required but missing" do
      result = described_class.call(user: teacher, role: "question_author", action: :add)
      expect(result).to be_failure
      expect(result.error).to eq "Must include a subject with a lesson or question author role"
    end

    it "fails (rather than raising) when role is unrecognised" do
      result = described_class.call(user: teacher, role: "wizard", action: :add)
      expect(result).to be_failure
      expect(result.error).to match(/unrecognised role/i)
    end
  end

  describe "success paths" do
    it "adds the school_admin role" do
      result = described_class.call(user: teacher, role: "school_admin", action: :add)
      expect(result).to be_success
      expect(teacher).to have_role(:school_admin)
    end

    context "with a target subject" do
      let(:subject) { create(:subject) }

      it "adds a question_author role scoped to the subject" do
        result = described_class.call(user: teacher, role: "question_author", action: :add, subject: subject.id)
        expect(result).to be_success
        expect(teacher).to have_role(:question_author, subject)
      end
    end

    context "with a previously assigned role" do
      before { teacher.add_role(:school_admin) }

      it "removes the role" do
        result = described_class.call(user: teacher, role: "school_admin", action: :remove)
        expect(result).to be_success
        expect(teacher).not_to have_role(:school_admin)
      end
    end
  end
end
