# frozen_string_literal: true

require "rails_helper"
require "support/api_data"

RSpec.describe User do
  it "has a valid factory" do
    expect(build(:user)).to be_valid
  end

  describe "validations" do
    subject { build(:user) }

    it { is_expected.to validate_presence_of :upi }
    it { is_expected.to validate_presence_of :role }
  end

  describe "#from_wonde" do
    include_context "with api_data"

    let(:classroom) { create(:classroom) }

    before do
      school_api_data
    end

    context "with student API data" do
      it "does not allow students missing a upi" do
        expect { create(:student, upi: "") }.to raise_error(ActiveRecord::RecordInvalid)
      end

      context "when students are assigned to a mapped subject" do
        before { classroom_api_data.students = user_api_data }

        it "creates students for a mapped subject" do
          described_class.from_wonde(school_api_data, classroom_api_data, classroom)
          expect(described_class.find_by!(role: "student").forename).to eq(user_api_data.data[0].forename)
        end

        it "generates a username" do
          described_class.from_wonde(school_api_data, classroom_api_data, classroom)
          u = user_api_data.data[0]
          expect(described_class.find_by!(role: "student").username)
            .to eq(u.forename[0].downcase + u.surname.downcase + u.upi[0..3])
        end
      end

      context "when employees are assigned to a mapped subject" do
        before do
          classroom_api_data.employees = user_api_data
          allow(school_api).to receive(:get).and_return(contact_details_api_data)
        end

        it "creates employees for a mapped subject" do
          described_class.from_wonde(school_api_data, classroom_api_data, classroom)
          expect(described_class.find_by!(role: "employee").forename).to eq(user_api_data.data[0].forename)
        end
      end

      context "when the classroom subject is unmapped" do
        before { classroom_api_data.subject.data.name = "Not a subject" }

        it "creates no accounts" do
          described_class.from_wonde(school_api_data, classroom_api_data, classroom)
          expect(described_class.count).to be_zero
        end
      end

      context "when both employees and students are present" do
        before do
          classroom_api_data.students = user_api_data
          classroom_api_data.employees = alt_user_api_data
          allow(school_api).to receive(:get).and_return(contact_details_api_data)
        end

        it "creates accounts for both employees and students" do
          described_class.from_wonde(school_api_data, classroom_api_data, classroom)
          expect(described_class.count).to eq(2)
        end
      end

      context "when duplicate usernames exist" do
        before { classroom_api_data.students = duplicate_user_api_data }

        it "generates a unique username for duplicates" do
          described_class.from_wonde(school_api_data, classroom_api_data, classroom)
          u = duplicate_user_api_data.data[1]
          expect(described_class.second.username)
            .to start_with(u.forename[0].downcase + u.surname.downcase)
        end
      end

      context "when a user record already exists" do
        it "preserves the existing username" do
          pending "from_wonde overwrites username for existing users — model behavior needs investigation"
          described_class.create(upi: user_api_data.upi, username: "test")
          classroom_api_data.employees = user_api_data
          allow(school_api).to receive(:get).and_return(contact_details_api_data)
          described_class.from_wonde(school_api_data, classroom_api_data, classroom)
          expect(described_class.first.username).to eq("test")
        end
      end
    end
  end
end
