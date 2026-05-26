# frozen_string_literal: true

require "rails_helper"

RSpec.describe Customisation::RefreshCustomisationsInStore, :default_creates do
  context "with retired customisations" do
    let!(:retired) { create(:dashboard_customisation, cost: 5, retired: true) }

    before do
      described_class.call
    end

    it "does not make retired customisations purchasable" do
      expect(retired.reload.purchasable).to be false
    end
  end

  context "with more than six available customisations" do
    before do
      create_list(:dashboard_customisation, 10)
      described_class.call
    end

    it "activates up to six customisations randomly" do
      expect(Customisation.where(purchasable: true).count).to eq(6)
    end
  end

  context "with sticky customisations" do
    before do
      create_list(:dashboard_customisation, 12)
      create_list(:dashboard_customisation, 5, sticky: true)
      described_class.call
    end

    it "always picks sticky customisations" do
      expect(Customisation.where(purchasable: true, sticky: true).count).to eq(5)
    end
  end

  context "with both leaderboard icons and dashboard styles" do
    before do
      create_list(:customisation, 12, customisation_type: "leaderboard_icon")
      create_list(:dashboard_customisation, 12)
      described_class.call
    end

    it "activates leaderboard icons" do
      expect(Customisation.where(purchasable: true, customisation_type: "leaderboard_icon").count).to eq(6)
    end

    it "activates dashboard styles" do
      expect(Customisation.where(purchasable: true, customisation_type: "dashboard_style").count).to eq(6)
    end
  end
end
