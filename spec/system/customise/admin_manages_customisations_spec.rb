# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin manages customisations", :default_creates, :js do
  let(:new_name) { FFaker::Lorem.word }

  before do
    sign_in super_admin
  end

  def fill_in_customisation_form
    fill_in("Name", with: new_name)
    fill_in("Value", with: "blue")
    fill_in("Cost", with: "200")
  end

  context "when viewing the customisation index" do
    let!(:available_customisation) { create(:dashboard_customisation, purchasable: true) }
    let!(:unavailable_customisation) { create(:dashboard_customisation, purchasable: false) }
    let!(:retired_customisation) { create(:dashboard_customisation, retired: true) }
    let!(:sticky_customisation) { create(:dashboard_customisation, sticky: true, purchasable: true) }

    before { visit customisations_path }

    it "orders cards by sticky, then available, then unavailable, with status badges" do
      within("section.available-customisations") do
        expect(page).to have_css(".card", count: 3)
        cards = all(".card")
        expect(cards[0]).to have_text(sticky_customisation.name.upcase).and have_text("STICKIED")
        expect(cards[1]).to have_text(available_customisation.name.upcase)
        expect(cards[2]).to have_text(unavailable_customisation.name.upcase).and have_text("UNAVAILABLE")
      end
    end

    it "shows retired customisations in their own section" do
      expect(page).to have_css("section.retired-customisations .card", text: retired_customisation.name.upcase)
    end
  end

  context "when editing a dashboard style" do
    let(:available_customisation) { create(:dashboard_customisation, purchasable: true) }

    before do
      visit(edit_customisation_path(available_customisation))
    end

    it "updates the name" do
      fill_in("Name", with: new_name)
      click_button("Update Customisation")
      expect(page).to have_content(new_name.upcase)
    end

    it "updates the value" do
      fill_in("Value", with: "blue")
      click_button("Update Customisation")
      expect(page).to have_css(".heading-divider[style*='blue']")
    end

    it "updates the picture" do
      attach_file("Image", Rails.root.join("spec/fixtures/files/computer-science.jpg").to_s)
      click_button("Update Customisation")
      expect(page).to have_css('div [style*="computer-science.jpg"]')
    end

    it "updates if it is sticky" do
      check("Sticky")
      click_button("Update Customisation")
      expect(page).to have_content("Stickied".upcase)
    end

    it "updates the purchasable flag" do
      uncheck("Purchasable")
      click_button("Update Customisation")
      expect(page).to have_content("Unavailable".upcase)
    end
  end

  context "when creating a dashboard style" do
    before do
      visit new_customisation_path
    end

    it "creates the customisation" do
      fill_in_customisation_form
      attach_file("Image", Rails.root.join("spec/fixtures/files/game-pieces.jpg").to_s)
      click_button("Create Customisation")
      expect(page).to have_content(new_name.upcase)
    end
  end

  context "when creating a leaderboard icon" do
    before do
      visit new_customisation_path
    end

    it "creates the customisation" do
      select "Leaderboard icon", from: "customisation_customisation_type"
      fill_in_customisation_form
      fill_in("Value", with: "blue,cheese")
      click_button("Create Customisation")
      expect(page).to have_content(new_name)
    end
  end
end
