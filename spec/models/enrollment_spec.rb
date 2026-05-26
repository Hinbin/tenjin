# frozen_string_literal: true

require "rails_helper"
require "support/api_data"

RSpec.describe Enrollment do
  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:classroom) }

  it "has a valid factory" do
    expect(build(:enrollment)).to be_valid
  end

  describe "validation" do
    subject { build(:enrollment) }

    it { is_expected.to validate_uniqueness_of(:user).scoped_to(:classroom_id) }
  end

  context "when a user is enrolled in one classroom" do
    let(:school) { create(:school, client_id: "1234") }
    let(:classrooms) { create_list(:classroom, 2, school: school) }
    let(:student) { create(:student, school: school) }

    before do
      create(:enrollment, classroom: classrooms[0], user: student)
    end

    it "allows enrollment in multiple classrooms" do
      expect { create(:enrollment, classroom: classrooms[1], user: student) }.not_to raise_error
    end

    it "raises an error on duplicate enrollment" do
      expect { create(:enrollment, classroom: classrooms[0], user: student) }
        .to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe "#from_wonde" do
    include_context "with api_data"

    before do
      school_api_data
      create(:classroom, client_id: "classroom_id", school: School.first)
      create(:student, upi: user_api_data.data[0].upi, school: School.first)
      classroom_api_data.id = "classroom_id"
    end

    it "creates student enrollments" do
      classroom_api_data.students = user_api_data
      described_class.from_wonde(classroom_api_data)
      expect(described_class.count).to eq(1)
    end

    it "creates employee enrollments" do
      classroom_api_data.employees = user_api_data
      described_class.from_wonde(classroom_api_data)
      expect(described_class.count).to eq(1)
    end

    it "enables the classroom" do
      classroom_api_data.employees = user_api_data
      described_class.from_wonde(classroom_api_data)
      expect(Classroom.first).not_to be_disabled
    end

    context "when no students or employees are present" do
      it "creates no enrollments" do
        described_class.from_wonde(classroom_api_data)
        expect(described_class.count).to eq(0)
      end
    end

    context "when a prior sync has already run" do
      before do
        classroom_api_data.students = user_api_data
        School.from_wonde(school_api_data, classroom_api_data)
        described_class.from_wonde(classroom_api_data)
      end

      context "when a different student is synced" do
        before do
          classroom_api_data.students = alt_user_api_data
          described_class.from_wonde(classroom_api_data)
        end

        it "removes old enrollments" do
          expect(described_class.count).to eq(0)
        end

        it "disables classrooms with no enrollments" do
          expect(Classroom.first).to be_disabled
        end
      end
    end
  end
end
