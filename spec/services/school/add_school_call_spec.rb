# frozen_string_literal: true

require "rails_helper"

RSpec.describe School::AddSchool, :vcr do
  let(:school_token) { "2a550dc912f6a63488af42352b79c5961e87daf9" }
  let(:school_id) { "A852030759" }
  let(:school_params) { ActionController::Parameters.new(token: school_token, client_id: school_id) }

  def sync_school
    described_class.call(school_params)
  end

  context "when no matching school exists" do
    before { sync_school }

    it "creates the school from the Wonde data" do
      expect(School.find_by(client_id: school_id).name).to eq "Outwood Grange Academy 1532082212"
    end
  end

  context "when a school with the same client_id exists" do
    before do
      create(:school, name: "Not outwood", client_id: "A852030759")
      sync_school
    end

    it "updates the school name in place without creating a duplicate" do
      expect(School.count).to eq(1)
      expect(School.find_by(client_id: school_id).name).to eq "Outwood Grange Academy 1532082212"
    end
  end
end
