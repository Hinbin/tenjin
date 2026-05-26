# frozen_string_literal: true

require "rails_helper"

RSpec.describe School::AddSchool do
  let(:school_token) { "2a550dc912f6a63488af42352b79c5961e87daf9" }
  let(:school_id) { "A852030759" }
  let(:school_params) { ActionController::Parameters.new(token: school_token, client_id: school_id) }

  def sync_school
    described_class.call(school_params)
  end

  def school_in_db
    School.find_by(name: "Outwood Grange Academy 1532082212")
  end

  context "when using Wonde API data" do
    before do
      sync_school
    end

    it "creates a school", :vcr do
      expect(school_in_db.name).to eq "Outwood Grange Academy 1532082212"
    end
  end

  context "when given updated school data" do
    before do
      create(:school, name: "Not outwood", client_id: "A852030759")
      sync_school
    end

    it "updates the school name", :vcr do
      expect(School.find_by(client_id: school_id).name).to eq "Outwood Grange Academy 1532082212"
    end

    it "does not create a duplicate school", :vcr do
      expect(School.count).to eq(1)
    end
  end
end
