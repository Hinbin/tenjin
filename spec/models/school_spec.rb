# frozen_string_literal: true

require "rails_helper"

RSpec.describe School do
  it "has a valid factory" do
    expect(build(:school)).to be_valid
  end

  describe "validations" do
    subject { build(:school) }

    it { is_expected.to validate_presence_of(:client_id) }
    it { is_expected.to validate_uniqueness_of(:client_id) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:token) }
  end

  describe "#from_wonde" do
    let(:school) { described_class.from_wonde(OpenStruct.new(id: "1234", name: "test"), "token") }

    it "persists the school" do
      expect(school).to be_persisted
    end

    context "when a matching school already exists" do
      before { create(:school, client_id: "1234", name: "old name") }

      it "updates the existing school attributes" do
        expect(school).to have_attributes(client_id: "1234", name: "test")
      end
    end
  end
end
